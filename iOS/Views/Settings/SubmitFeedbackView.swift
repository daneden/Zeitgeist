//
//  SubmitFeedbackView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SubmitFeedbackView: View {
  enum FormState {
    case idle, submitting, completed, error
  }
  
  @State var currentState: FormState = .idle
  @AppStorage("feedbackName") var name = ""
  @AppStorage("feedbackEmail") var email = ""
  @State var message = ""
  
  var inputIsValid: Bool {
    !message.isEmpty
  }
  
  var body: some View {
    Form {
      Section(footer: Text("Your name and email address are optional, but can be helpful for getting more information about reported issues.")) {
        TextField("Your Name (Optional)", text: $name)
        TextField("Email Address (Optional)", text: $email)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
        DeploymentDetailLabel("Feedback:") {
          TextEditor(text: $message)
        }
        
        Button(action: submitFeedback) {
          HStack {
            Text("Submit")
            
            if currentState == .submitting {
              Spacer()
              ProgressView()
            }
          }
        }
        .disabled(!inputIsValid || currentState == .submitting)
        
        Group {
          if message.isEmpty && currentState == .completed {
            Label("Feedback submitted. Thank you for helping to make Zeitgeist better!", systemImage: "heart.fill")
              .accentColor(.systemPink)
          }
          
          if currentState == .error {
            Label("There was a problem submitting feedback. Please try again later or leave your feedback in a review on the App Store.", systemImage: "exclamationmark.triangle.fill")
              .accentColor(.systemRed)
          }
        }
        .padding(.vertical, 4)
        .font(.footnote.weight(.medium))
      }
    }
    .transition(.slide)
    .navigationTitle("Submit Feedback")
  }
  
  func submitFeedback() {
    currentState = .submitting
    
    let url = URL(string: "https://zeitgeist.daneden.me/api/submit-feedback")!
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    let json: [String: Any] = [
      "name": name,
      "email": email.lowercased(),
      "feedback": message,
      "appVersion": appVersion ?? "Unknown"
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    request.httpBody = jsonData
    
    URLSession.shared.dataTask(with: request) { data, response, error in
      if let response = response as? HTTPURLResponse,
         response.statusCode == 200 {
        DispatchQueue.main.async {
          self.currentState = .completed
          clearForm()
        }
      } else {
        DispatchQueue.main.async {
          self.currentState = .error
        }
      }
    }.resume()
  }
  
  func clearForm() {
    message = ""
  }
}

struct SubmitFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitFeedbackView()
    }
}
