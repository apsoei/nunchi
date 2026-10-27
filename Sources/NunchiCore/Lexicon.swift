/// 단어 끝 판별용 작은 사전. 규칙(낱자모)으로는 못 잡고 한글로도 그럴듯하게 쳐지는 영어 단어만 담는다.
/// 목록은 직접 골랐다(외부 단어 목록을 넣지 않음). 규칙으로 이미 잡히는 단어는 넣을 필요가 없다.
enum Lexicon {
    static let english: Set<String> = [
        // 일반 단어
        "a", "i", "the", "to", "and", "for", "with", "do", "did", "they", "she", "an", "their", "so", "who",
        "go", "got", "when", "them", "than", "then", "also", "work", "such", "down", "always", "right",
        "sorry", "end", "turn", "run", "show", "fix", "goal", "fun", "throw",
        // 개발·업무 용어
        "git", "sudo", "curl", "ll", "rm", "cp", "vi", "cmake", "gh", "xml", "ci", "env", "vo", "slack", "figma",
    ]

    /// 위 영어 단어를 한글로 쳤을 때 실제로 흔한 한국어 단어가 되는 것. 이 경우는 앞 단어 언어를 따른다.
    static let korean: Set<String> = [
        "새", "해", "애", "내", "무", "그", "체", "패", "호", "양", "햇", "둥",
    ]
}
