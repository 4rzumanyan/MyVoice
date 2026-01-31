import Foundation

/// Represents a language for output translation
struct OutputLanguage: Identifiable, Codable, Equatable, Hashable {
    let code: String
    let name: String
    let flag: String
    
    var id: String { code }
    var displayName: String { "\(flag) \(name)" }
    
    // MARK: - Default
    
    static let english = OutputLanguage(code: "en", name: "English", flag: "🇺🇸")
    
    // MARK: - All Languages (sorted alphabetically by name)
    
    static let allLanguages: [OutputLanguage] = [
        OutputLanguage(code: "af", name: "Afrikaans", flag: "🇿🇦"),
        OutputLanguage(code: "sq", name: "Albanian", flag: "🇦🇱"),
        OutputLanguage(code: "am", name: "Amharic", flag: "🇪🇹"),
        OutputLanguage(code: "ar", name: "Arabic", flag: "🇸🇦"),
        OutputLanguage(code: "hy", name: "Armenian", flag: "🇦🇲"),
        OutputLanguage(code: "az", name: "Azerbaijani", flag: "🇦🇿"),
        OutputLanguage(code: "eu", name: "Basque", flag: "🇪🇸"),
        OutputLanguage(code: "be", name: "Belarusian", flag: "🇧🇾"),
        OutputLanguage(code: "bn", name: "Bengali", flag: "🇧🇩"),
        OutputLanguage(code: "bs", name: "Bosnian", flag: "🇧🇦"),
        OutputLanguage(code: "bg", name: "Bulgarian", flag: "🇧🇬"),
        OutputLanguage(code: "my", name: "Burmese", flag: "🇲🇲"),
        OutputLanguage(code: "ca", name: "Catalan", flag: "🇪🇸"),
        OutputLanguage(code: "zh", name: "Chinese (Simplified)", flag: "🇨🇳"),
        OutputLanguage(code: "zh-TW", name: "Chinese (Traditional)", flag: "🇹🇼"),
        OutputLanguage(code: "hr", name: "Croatian", flag: "🇭🇷"),
        OutputLanguage(code: "cs", name: "Czech", flag: "🇨🇿"),
        OutputLanguage(code: "da", name: "Danish", flag: "🇩🇰"),
        OutputLanguage(code: "nl", name: "Dutch", flag: "🇳🇱"),
        OutputLanguage(code: "en", name: "English", flag: "🇺🇸"),
        OutputLanguage(code: "et", name: "Estonian", flag: "🇪🇪"),
        OutputLanguage(code: "fi", name: "Finnish", flag: "🇫🇮"),
        OutputLanguage(code: "fr", name: "French", flag: "🇫🇷"),
        OutputLanguage(code: "gl", name: "Galician", flag: "🇪🇸"),
        OutputLanguage(code: "ka", name: "Georgian", flag: "🇬🇪"),
        OutputLanguage(code: "de", name: "German", flag: "🇩🇪"),
        OutputLanguage(code: "el", name: "Greek", flag: "🇬🇷"),
        OutputLanguage(code: "gu", name: "Gujarati", flag: "🇮🇳"),
        OutputLanguage(code: "ht", name: "Haitian Creole", flag: "🇭🇹"),
        OutputLanguage(code: "ha", name: "Hausa", flag: "🇳🇬"),
        OutputLanguage(code: "he", name: "Hebrew", flag: "🇮🇱"),
        OutputLanguage(code: "hi", name: "Hindi", flag: "🇮🇳"),
        OutputLanguage(code: "hu", name: "Hungarian", flag: "🇭🇺"),
        OutputLanguage(code: "is", name: "Icelandic", flag: "🇮🇸"),
        OutputLanguage(code: "ig", name: "Igbo", flag: "🇳🇬"),
        OutputLanguage(code: "id", name: "Indonesian", flag: "🇮🇩"),
        OutputLanguage(code: "ga", name: "Irish", flag: "🇮🇪"),
        OutputLanguage(code: "it", name: "Italian", flag: "🇮🇹"),
        OutputLanguage(code: "ja", name: "Japanese", flag: "🇯🇵"),
        OutputLanguage(code: "jv", name: "Javanese", flag: "🇮🇩"),
        OutputLanguage(code: "kn", name: "Kannada", flag: "🇮🇳"),
        OutputLanguage(code: "kk", name: "Kazakh", flag: "🇰🇿"),
        OutputLanguage(code: "km", name: "Khmer", flag: "🇰🇭"),
        OutputLanguage(code: "rw", name: "Kinyarwanda", flag: "🇷🇼"),
        OutputLanguage(code: "ko", name: "Korean", flag: "🇰🇷"),
        OutputLanguage(code: "ku", name: "Kurdish", flag: "🇮🇶"),
        OutputLanguage(code: "ky", name: "Kyrgyz", flag: "🇰🇬"),
        OutputLanguage(code: "lo", name: "Lao", flag: "🇱🇦"),
        OutputLanguage(code: "lv", name: "Latvian", flag: "🇱🇻"),
        OutputLanguage(code: "lt", name: "Lithuanian", flag: "🇱🇹"),
        OutputLanguage(code: "lb", name: "Luxembourgish", flag: "🇱🇺"),
        OutputLanguage(code: "mk", name: "Macedonian", flag: "🇲🇰"),
        OutputLanguage(code: "mg", name: "Malagasy", flag: "🇲🇬"),
        OutputLanguage(code: "ms", name: "Malay", flag: "🇲🇾"),
        OutputLanguage(code: "ml", name: "Malayalam", flag: "🇮🇳"),
        OutputLanguage(code: "mt", name: "Maltese", flag: "🇲🇹"),
        OutputLanguage(code: "mi", name: "Maori", flag: "🇳🇿"),
        OutputLanguage(code: "mr", name: "Marathi", flag: "🇮🇳"),
        OutputLanguage(code: "mn", name: "Mongolian", flag: "🇲🇳"),
        OutputLanguage(code: "ne", name: "Nepali", flag: "🇳🇵"),
        OutputLanguage(code: "no", name: "Norwegian", flag: "🇳🇴"),
        OutputLanguage(code: "ny", name: "Nyanja", flag: "🇲🇼"),
        OutputLanguage(code: "or", name: "Odia", flag: "🇮🇳"),
        OutputLanguage(code: "ps", name: "Pashto", flag: "🇦🇫"),
        OutputLanguage(code: "fa", name: "Persian", flag: "🇮🇷"),
        OutputLanguage(code: "pl", name: "Polish", flag: "🇵🇱"),
        OutputLanguage(code: "pt", name: "Portuguese", flag: "🇧🇷"),
        OutputLanguage(code: "pa", name: "Punjabi", flag: "🇮🇳"),
        OutputLanguage(code: "ro", name: "Romanian", flag: "🇷🇴"),
        OutputLanguage(code: "ru", name: "Russian", flag: "🇷🇺"),
        OutputLanguage(code: "sm", name: "Samoan", flag: "🇼🇸"),
        OutputLanguage(code: "gd", name: "Scottish Gaelic", flag: "🏴󠁧󠁢󠁳󠁣󠁴󠁿"),
        OutputLanguage(code: "sr", name: "Serbian", flag: "🇷🇸"),
        OutputLanguage(code: "st", name: "Sesotho", flag: "🇱🇸"),
        OutputLanguage(code: "sn", name: "Shona", flag: "🇿🇼"),
        OutputLanguage(code: "sd", name: "Sindhi", flag: "🇵🇰"),
        OutputLanguage(code: "si", name: "Sinhala", flag: "🇱🇰"),
        OutputLanguage(code: "sk", name: "Slovak", flag: "🇸🇰"),
        OutputLanguage(code: "sl", name: "Slovenian", flag: "🇸🇮"),
        OutputLanguage(code: "so", name: "Somali", flag: "🇸🇴"),
        OutputLanguage(code: "es", name: "Spanish", flag: "🇪🇸"),
        OutputLanguage(code: "su", name: "Sundanese", flag: "🇮🇩"),
        OutputLanguage(code: "sw", name: "Swahili", flag: "🇰🇪"),
        OutputLanguage(code: "sv", name: "Swedish", flag: "🇸🇪"),
        OutputLanguage(code: "tl", name: "Tagalog", flag: "🇵🇭"),
        OutputLanguage(code: "tg", name: "Tajik", flag: "🇹🇯"),
        OutputLanguage(code: "ta", name: "Tamil", flag: "🇮🇳"),
        OutputLanguage(code: "tt", name: "Tatar", flag: "🇷🇺"),
        OutputLanguage(code: "te", name: "Telugu", flag: "🇮🇳"),
        OutputLanguage(code: "th", name: "Thai", flag: "🇹🇭"),
        OutputLanguage(code: "tr", name: "Turkish", flag: "🇹🇷"),
        OutputLanguage(code: "tk", name: "Turkmen", flag: "🇹🇲"),
        OutputLanguage(code: "uk", name: "Ukrainian", flag: "🇺🇦"),
        OutputLanguage(code: "ur", name: "Urdu", flag: "🇵🇰"),
        OutputLanguage(code: "ug", name: "Uyghur", flag: "🇨🇳"),
        OutputLanguage(code: "uz", name: "Uzbek", flag: "🇺🇿"),
        OutputLanguage(code: "vi", name: "Vietnamese", flag: "🇻🇳"),
        OutputLanguage(code: "cy", name: "Welsh", flag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿"),
        OutputLanguage(code: "xh", name: "Xhosa", flag: "🇿🇦"),
        OutputLanguage(code: "yi", name: "Yiddish", flag: "🇮🇱"),
        OutputLanguage(code: "yo", name: "Yoruba", flag: "🇳🇬"),
        OutputLanguage(code: "zu", name: "Zulu", flag: "🇿🇦")
    ]
    
    // MARK: - Lookup
    
    static func language(forCode code: String) -> OutputLanguage {
        allLanguages.first { $0.code == code } ?? .english
    }
}
