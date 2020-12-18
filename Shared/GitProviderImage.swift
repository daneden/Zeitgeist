//
//  GitProviderImage.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 18/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

let imageMap: [GitSVNProvider: String] = [
  .bitbucket: "BitBucket",
  .github: "GitHub",
  .gitlab: "GitLab"
]

struct GitProviderImage: View {
  var provider: GitSVNProvider
    var body: some View {
        Image(imageMap[provider]!)
          
    }
}

struct GitProviderImage_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        GitProviderImage(provider: .github)
          .previewLayout(.sizeThatFits)
          .padding()
          .previewDisplayName("GitHub")
        GitProviderImage(provider: .gitlab)
          .previewLayout(.sizeThatFits)
          .padding()
          .previewDisplayName("GitLab")
        GitProviderImage(provider: .bitbucket)
          .previewLayout(.sizeThatFits)
          .padding()
          .previewDisplayName("BitBucket")
        GitProviderImage(provider: .github)
          .environment(\.colorScheme, .dark)
          .previewLayout(.sizeThatFits)
          .padding()
          .background(Color.black)
          .previewDisplayName("GitHub Dark")
        GitProviderImage(provider: .gitlab)
          .environment(\.colorScheme, .dark)
          .previewLayout(.sizeThatFits)
          .padding()
          .background(Color.black)
          .previewDisplayName("GitLab Dark")
        GitProviderImage(provider: .bitbucket)
          .environment(\.colorScheme, .dark)
          .previewLayout(.sizeThatFits)
          .padding()
          .background(Color.black)
          .previewDisplayName("BitBucket Dark")
      }
    }
}
