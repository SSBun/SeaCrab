//
//  AppSettings.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Carbon
import Foundation
import SwiftUI

// MARK: - BuiltInPrompt

enum BuiltInPrompt: String, CaseIterable, Identifiable {
    case grammarAndSpelling = "Grammar & Spelling Only"
    
    var id: String { rawValue }
    
    var prompt: String {
        switch self {
        case .grammarAndSpelling:
            return """
            You are an expert proofreader. Your task is to refine the provided text, focusing exclusively on correcting grammar issues and spelling errors, while strictly adhering to the following guidelines:
            
            1.  **Preserve Original Meaning:** Do not alter the core message or intent of the original text.
            2.  **No Sentence Extension:** Do not add new information or extend the length of existing sentences.
            3.  **No Sentence Structure Modification:** Do not change the existing sentence structure, flow, or transitions between sentences.
            4.  **No Tone Modification:** Do not alter the tone of the text in any way.
            5.  **No Word Choice Modification:** Do not suggest alternative word choices for conciseness or impact. Only correct misspelled words.
            6.  **Grammar and Punctuation:** Correct all grammatical errors and punctuation issues.
            7.  **Spelling:** Correct all spelling mistakes.
            8.  **Return Original if Correct:** If the text is already grammatically correct and free of spelling errors, return the original text unchanged.
            
            Present only the refined text. Do not include explanations or commentary.
            """
        }
    }
}

// MARK: - AppSettings

/// Application settings stored in UserDefaults
@Observable
class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let apiKey = "apiKey"
        static let baseURL = "baseURL"
        static let model = "model"
        static let refinementCards = "refinementCards"
    }
    
    var apiKey: String {
        get { defaults.string(forKey: Keys.apiKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.apiKey) }
    }
    
    var baseURL: String {
        get { defaults.string(forKey: Keys.baseURL) ?? "https://api.openai.com/v1" }
        set { defaults.set(newValue, forKey: Keys.baseURL) }
    }
    
    var model: String {
        get { defaults.string(forKey: Keys.model) ?? "gpt-4o" }
        set { defaults.set(newValue, forKey: Keys.model) }
    }
    
    var refinementCards: [RefinementCard] {
        get {
            guard let data = defaults.data(forKey: Keys.refinementCards),
                  let cards = try? JSONDecoder().decode([RefinementCard].self, from: data) else {
                return [RefinementCard.defaultCard]
            }
            return cards
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.refinementCards)
            }
        }
    }
    
    func addCard(_ card: RefinementCard) {
        var cards = refinementCards
        cards.append(card)
        refinementCards = cards
    }
    
    func removeCard(_ card: RefinementCard) {
        var cards = refinementCards
        cards.removeAll { $0.id == card.id }
        refinementCards = cards
    }
    
    func updateCard(_ card: RefinementCard) {
        var cards = refinementCards
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
            refinementCards = cards
        }
    }
    
    private init() {}
}
