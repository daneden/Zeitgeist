//
//  PlaceholderData.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 07/08/2022.
//

import Foundation

extension VercelProject {
	static var exampleData: VercelProject {
		let jsonData = """
		{
		  "accountId": "ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		  "autoExposeSystemEnvs": true,
		  "buildCommand": null,
		  "createdAt": 1659643229407,
		  "devCommand": null,
		  "directoryListing": false,
		  "env": [],
		  "framework": "nextjs",
		  "gitForkProtection": true,
		  "id": "prj_TwmwXFAcQ7eGeQdqRjBasDzBUMne",
		  "installCommand": null,
		  "name": "example-project",
		  "nodeVersion": "16.x",
		  "outputDirectory": null,
		  "publicSource": null,
		  "rootDirectory": null,
		  "serverlessFunctionRegion": "iad1",
		  "sourceFilesOutsideRootDirectory": true,
		  "updatedAt": 1659860840289,
		  "live": false,
		  "link": {
		    "type": "github",
		    "repo": "example-repo",
		    "repoId": 521398877,
		    "org": "example",
		    "gitCredentialId": "example_id",
		    "productionBranch": "main",
		    "sourceless": true,
		    "createdAt": 1659643229351,
		    "updatedAt": 1659643229351,
		    "deployHooks": [
		      {
		        "createdAt": 1659707819534,
		        "id": "MQmjZVn2NQ",
		        "name": "Example Webhook",
		        "ref": "main",
		        "url": "https://api.vercel.com/"
		      }
		    ]
		  },
		  "latestDeployments": [
		    {
		      "alias": ["example.com", "example.vercel.app"],
		      "aliasAssigned": 1659860877358,
		      "aliasError": null,
		      "builds": [],
		      "createdAt": 1659860840191,
		      "createdIn": "sfo1",
		      "creator": {
		        "uid": "ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		        "email": "dan.eden@me.com",
		        "username": "daneden",
		        "githubLogin": "daneden"
		      },
		      "deploymentHostname": "example",
		      "forced": false,
		      "id": "dpl_ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		      "meta": {
		        "githubCommitAuthorName": "Max Mayfield",
		        "githubCommitMessage": "Example commit message",
		        "githubCommitOrg": "example",
		        "githubCommitRef": "main",
		        "githubCommitRepo": "example-repo",
		        "githubCommitSha": "ce79c4239488ecb16cfcbad767d5188ce131cee8",
		        "githubDeployment": "1",
		        "githubOrg": "example",
		        "githubRepo": "example-repo",
		        "githubCommitRepoId": "12345678",
		        "githubRepoId": "12345678",
		        "githubCommitAuthorLogin": "maxmay"
		      },
		      "name": "example-project",
		      "plan": "hobby",
		      "private": true,
		      "readyState": "READY",
		      "target": "production",
		      "teamId": null,
		      "type": "LAMBDAS",
		      "url": "example.vercel.app",
		      "userId": "ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		      "withCache": false
		    }
		  ],
		  "targets": {
		    "production": {
		      "alias": ["example.com", "example.vercel.app"],
		      "aliasAssigned": 1659860877358,
		      "aliasError": null,
		      "builds": [],
		      "createdAt": 1659860840191,
		      "createdIn": "sfo1",
		      "creator": {
		        "uid": "ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		        "email": "dan.eden@me.com",
		        "username": "daneden",
		        "githubLogin": "daneden"
		      },
		      "deploymentHostname": "example",
		      "forced": false,
		      "id": "dpl_ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		      "meta": {
		        "githubCommitAuthorName": "Max Mayfield",
		        "githubCommitMessage": "Set locale for dates to prevent mismatches between server and client renders",
		        "githubCommitOrg": "daneden",
		        "githubCommitRef": "main",
		        "githubCommitRepo": "example-repo",
		        "githubCommitSha": "ce79c4239488ecb16cfcbad767d5188ce131cee8",
		        "githubDeployment": "1",
		        "githubOrg": "daneden",
		        "githubRepo": "example-repo",
		        "githubCommitRepoId": "521398877",
		        "githubRepoId": "521398877",
		        "githubCommitAuthorLogin": "daneden"
		      },
		      "name": "example-project",
		      "plan": "hobby",
		      "private": true,
		      "readyState": "READY",
		      "target": "production",
		      "teamId": null,
		      "type": "LAMBDAS",
		      "url": "example.vercel.app",
		      "userId": "ErNXfZNwbyDvjvkDpfbyqxqvA33W",
		      "withCache": false
		    }
		  }
		}

		""".data(using: .utf8)!
		return try! JSONDecoder().decode(VercelProject.self, from: jsonData)
	}
}
