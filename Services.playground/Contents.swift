//: # Swift currying in practice

import UIKit


// Stub post
class Post {}

enum ResponseError: ErrorType {
  // The server error has expired, please refresh it
  case SessionExpired
  
  // Any other error
  case OtherKindOfError
}

// Function to refresh the session
// This function connects to the server and perform a refresh token
func refreshSession(completion: () -> () ) {
  completion()
}

typealias CompletionClousure = ([Post]?, ResponseError?) -> ()

// Fetch the posts
func fetchPosts(userId: String, completion: CompletionClousure) {
  
  // This is a hack to try out the session expiry
  // If post = "123" then session is expired
  if userId == "123" {
    completion(nil, .SessionExpired)
    return
  }
  
  let posts = [Post(), Post()]
  completion(posts, nil)
}


//: ## First implementation
//:  Create a wrapper method to call refreshSession if needed

// Wrapping the original fetchPosts, this function refreshes the token if the server returns
// a SessionExpired error
func fetchPostsAndRefreshSessionIfNeeded(userId: String, completion: CompletionClousure) {
  
  fetchPosts(userId) { (posts: [Post]?, error) in
    
    if let error = error where error == .SessionExpired {
      
      refreshSession {
        print("Refresshing Session")
        fetchPosts(userId) { (posts: [Post]?, error) in
          
          // Display the posts
          completion([], nil)
        }
      }
      return
    }
    
    // Display the posts
    completion([], nil)
  }
}

// Example usage
fetchPostsAndRefreshSessionIfNeeded("123") { posts, error in
  print("Use posts to fill UI")
}

//: ## Second implementation
//:  Using currying

// Create a curried fetch posts function
func curriedFetchPost(userId userId: String)(completion: CompletionClousure) {
  fetchPosts(userId, completion: completion)
}

// Function that takes a server request partially applied function
func requestAndRefreshIfNeeded<T>(request: ((T, ResponseError?) -> ()) -> (), completion: (T, ResponseError?) -> ()) {
    
    request { (response, error) in
      
      if let error = error where error == .SessionExpired {
        
        refreshSession {
          print("Refresshing Session")
          request { (response, error) in
            
            // Display the posts
            completion(response, error)
          }
        }
        return
      }
      
      // Display the posts
      completion(response, error)
    }
}


requestAndRefreshIfNeeded(curriedFetchPost(userId: "123")) { (posts, error) in
  posts
  print("Use posts to fill UI")
}

//:  Reuse requestAndRefreshIfNeeded for comments request

// Stub comment
class Comment {}

// Original non curried method
func fetchComments(commentId: String, completion: ([Comment]?, ResponseError?) -> ()) {
  completion([Comment()], nil)
}

// Curried version
func curriedFetchComments(commentId: String)(completion: ([Comment]?, ResponseError?) -> ()) {
  fetchComments(commentId, completion: completion)
}

// Usage
requestAndRefreshIfNeeded(curriedFetchComments("123")) { (comments: [Comment]?, error) -> () in
  print("Comments fetched")
}
