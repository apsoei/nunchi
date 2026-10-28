/// 두벌식 키 입력을 한글로 조합한 결과.
public struct Composition: Equatable, Sendable {
    public let text: String
    /// 확정된 낱자모(ㅅㄴ 의 ㅅ)나 지금 홀로 있는 모음(ㅐ)이 있다. 한국어 단어를 바르게 칠 때는 생기지 않는다.
    public let hasOrphan: Bool
    /// 마지막 글자가 모음을 기다리는 낱자음이다(가ㄸ 의 ㄸ). 치는 도중에는 정상이지만 단어 끝에서는 이상하다.
    public let hasTrailingOrphan: Bool
    /// 끝에서부터 이어지는 낱자모 글자 수(좋앜ㅋ → 1, ㅋㅋ → 2, 경우 → 0).
    public let trailingLoneCount: Int
}

/// 두벌식 오토마타. 단어 하나 길이의 키 목록을 매번 처음부터 다시 조합한다(백스페이스가 단순해진다).
public enum HangulComposer {
    private struct Block {
        var cho: Character?
        var jung: Character?
        var jong: Character?

        var isEmpty: Bool { cho == nil && jung == nil }

        var rendered: Character? {
            if let cho, let jung { return Jamo.syllable(cho: cho, jung: jung, jong: jong) }
            return cho ?? jung
        }

        var isOrphan: Bool { !isEmpty && (cho == nil || jung == nil) }
    }

    public static func compose(_ keys: [Character]) -> Composition {
        var done: [Block] = []
        var cur = Block()

        func commit() {
            if !cur.isEmpty { done.append(cur) }
            cur = Block()
        }

        for key in keys {
            guard let j = Jamo.jamo(for: key) else { continue }
            if Jamo.isVowel(j) {
                if let jong = cur.jong {
                    // 받침이 다음 음절 초성으로 넘어간다. 겹받침이면 뒤쪽만 넘어간다.
                    let moved: Character
                    if let (first, second) = Jamo.splitFinals[jong] {
                        cur.jong = first
                        moved = second
                    } else {
                        cur.jong = nil
                        moved = jong
                    }
                    commit()
                    cur = Block(cho: moved, jung: j)
                } else if let jung = cur.jung {
                    if let compound = Jamo.compoundVowels[String([jung, j])] {
                        cur.jung = compound
                    } else {
                        commit()
                        cur = Block(jung: j)
                    }
                } else if cur.cho != nil {
                    cur.jung = j
                } else {
                    cur = Block(jung: j)
                }
            } else {
                if cur.cho != nil, cur.jung != nil, cur.jong == nil, Jamo.canBeFinal(j) {
                    cur.jong = j
                } else if let jong = cur.jong, let compound = Jamo.compoundFinals[String([jong, j])] {
                    cur.jong = compound
                } else {
                    commit()
                    cur = Block(cho: j)
                }
            }
        }

        let blocks = done + (cur.isEmpty ? [] : [cur])
        let text = String(blocks.compactMap(\.rendered))
        let hasOrphan = done.contains(where: \.isOrphan) || (cur.jung != nil && cur.cho == nil)
        let hasTrailingOrphan = cur.cho != nil && cur.jung == nil
        let trailingLoneCount = blocks.reversed().prefix(while: \.isOrphan).count
        return Composition(text: text, hasOrphan: hasOrphan, hasTrailingOrphan: hasTrailingOrphan,
                           trailingLoneCount: trailingLoneCount)
    }
}
