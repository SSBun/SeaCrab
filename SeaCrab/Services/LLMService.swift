//
//  LLMService.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Foundation
import OpenAI


enum LLMError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case missingAPIKey
    case missingBaseURL
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid API URL: '\(url)'. Must be a valid URL (e.g., https://api.openai.com/v1)"
        case .invalidResponse:
            return "Invalid response from API"
        case .missingAPIKey:
            return "API key is not configured"
        case .missingBaseURL:
            return "Base URL is not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

actor LLMService {
    private let settings = AppSettings.shared
    
    private func createClient() throws -> OpenAI {
        guard !settings.apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        let baseURLString = settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !baseURLString.isEmpty else {
            throw LLMError.missingBaseURL
        }
        
        // Parse the URL to extract host and path
        guard let baseURL = URL(string: baseURLString) else {
            throw LLMError.invalidURL(baseURLString)
        }
        
        // Extract host (domain) from the URL
        // The MacPaw/OpenAI SDK expects just the hostname like "api.openai.com"
        // not the full URL with scheme
        guard let host = baseURL.host else {
            throw LLMError.invalidURL(baseURLString)
        }
        
        // Construct the host string with optional path
        var hostString = host
        if baseURL.path != "/" && !baseURL.path.isEmpty {
            hostString += baseURL.path
        }
        
        // Construct the configuration with just the host
        let configuration = OpenAI.Configuration(
            token: settings.apiKey,
            host: hostString
        )
        
        return OpenAI(configuration: configuration)
    }
    
    func testConnection() async throws -> String {
        let client = try createClient()
        
        let query = ChatQuery(
            messages: [
                ChatQuery.ChatCompletionMessageParam(role: .user, content: "Hello, respond with 'OK' if you receive this message.")!
            ],
            model: .init(settings.model)
        )
        
        do {
            let result = try await client.chats(query: query)
            
            guard let content = result.choices.first?.message.content else {
                throw LLMError.invalidResponse
            }
            
            return "✅ Connection successful! Response: \(content)"
        } catch {
            throw LLMError.apiError(error.localizedDescription)
        }
    }
    
    func refineText(_ text: String, prompt: String) async throws -> String {
        let client = try createClient()
        
        guard let systemMessage = ChatQuery.ChatCompletionMessageParam(role: .system, content: prompt),
              let userMessage = ChatQuery.ChatCompletionMessageParam(role: .user, content: text)
        else {
            return text
        }
        
        let query = ChatQuery(
            messages: [systemMessage, userMessage],
            model: .init(settings.model),
            temperature: 0.7
        )
        
        do {
            let result = try await client.chats(query: query)
            
            guard let content = result.choices.first?.message.content else {
                throw LLMError.invalidResponse
            }
            
            // Only trim spaces and tabs, but preserve line breaks to maintain text structure
            return content.trimmingCharacters(in: .whitespaces)
        } catch {
            throw LLMError.networkError(error)
        }
    }
}

