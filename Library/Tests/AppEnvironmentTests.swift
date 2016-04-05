import XCTest
import Foundation
@testable import Library
@testable import KsApi
@testable import KsApi_TestHelpers
@testable import Models
@testable import Models_TestHelpers

final class AppEnvironmentTests : XCTestCase {

  func testPushAndPopEnvironment() {
    let lang = AppEnvironment.current.language

    AppEnvironment.pushEnvironment()
    XCTAssertEqual(lang, AppEnvironment.current.language)

    AppEnvironment.pushEnvironment(language: .es)
    XCTAssertEqual(Language.es, AppEnvironment.current.language)

    AppEnvironment.pushEnvironment(Environment())
    XCTAssertEqual(Language.en, AppEnvironment.current.language)

    AppEnvironment.popEnvironment()
    XCTAssertEqual(Language.es, AppEnvironment.current.language)

    AppEnvironment.popEnvironment()
    XCTAssertEqual(lang, AppEnvironment.current.language)

    AppEnvironment.popEnvironment()
  }

  func testReplaceCurrentEnvironment() {

    AppEnvironment.pushEnvironment(language: .es)
    XCTAssertEqual(AppEnvironment.current.language, Language.es)

    AppEnvironment.pushEnvironment(language: .fr)
    XCTAssertEqual(AppEnvironment.current.language, Language.fr)

    AppEnvironment.replaceCurrentEnvironment(language: Language.de)
    XCTAssertEqual(AppEnvironment.current.language, Language.de)

    AppEnvironment.popEnvironment()
    XCTAssertEqual(AppEnvironment.current.language, Language.es)
  }

  func testPersistenceKey() {

    XCTAssertEqual("com.kickstarter.AppEnvironment.current", AppEnvironment.environmentStorageKey,
                   "Failing this test means users will get logged out, so you better have a good reason.")
    XCTAssertEqual("com.kickstarter.AppEnvironment.oauthToken", AppEnvironment.oauthTokenStorageKey,
                   "Failing this test means user's tokens will be lost in ubiquitous storage, so you better have a good reason.")
  }

  func testUserSession() {
    AppEnvironment.pushEnvironment()

    XCTAssertNil(AppEnvironment.current.apiService.oauthToken)
    XCTAssertNil(AppEnvironment.current.currentUser)

    AppEnvironment.login(AccessTokenEnvelope(access_token: "deadbeef", user: UserFactory.user))

    XCTAssertEqual("deadbeef", AppEnvironment.current.apiService.oauthToken?.token)
    XCTAssertEqual(UserFactory.user, AppEnvironment.current.currentUser)

    AppEnvironment.updateCurrentUser(UserFactory.otherUser)

    XCTAssertEqual("deadbeef", AppEnvironment.current.apiService.oauthToken?.token)
    XCTAssertEqual(UserFactory.otherUser, AppEnvironment.current.currentUser)

    AppEnvironment.logout()

    XCTAssertNil(AppEnvironment.current.apiService.oauthToken)
    XCTAssertNil(AppEnvironment.current.currentUser)

    AppEnvironment.popEnvironment()
  }

  func testFromStorage_WithNothingStored() {
    let userDefaults = MockKeyValueStore()
    let ubiquitousStore = MockKeyValueStore()
    let env = AppEnvironment.fromStorage(ubiquitousStore: ubiquitousStore, userDefaults: userDefaults)

    XCTAssertNil(env.apiService.oauthToken?.token)
    XCTAssertEqual(nil, env.currentUser)
  }

  func testFromStorage_WithFullDataStored() {
    let userDefaults = MockKeyValueStore()
    let ubiquitousStore = MockKeyValueStore()

    userDefaults.setObject(
      [
        "apiService.oauthToken.token": "deadbeef",
        "apiService.serverConfig.apiBaseUrl": "http://api.ksr.com",
        "apiService.serverConfig.apiClientAuth.clientId": "cafebeef",
        "apiService.serverConfig.basicHTTPAuth.username": "hola",
        "apiService.serverConfig.basicHTTPAuth.password": "mundo",
        "apiService.serverConfig.webBaseUrl": "http://ksr.com",
        "apiService.language": "en",
        "currentUser": UserFactory.user.encode()
      ],
      forKey: AppEnvironment.environmentStorageKey)

    let env = AppEnvironment.fromStorage(ubiquitousStore: ubiquitousStore, userDefaults: userDefaults)

    XCTAssertEqual("deadbeef", env.apiService.oauthToken?.token)
    XCTAssertEqual("http://api.ksr.com", env.apiService.serverConfig.apiBaseUrl.absoluteString)
    XCTAssertEqual("cafebeef", env.apiService.serverConfig.apiClientAuth.clientId)
    XCTAssertEqual("hola", env.apiService.serverConfig.basicHTTPAuth?.username)
    XCTAssertEqual("mundo", env.apiService.serverConfig.basicHTTPAuth?.password)
    XCTAssertEqual("http://ksr.com", env.apiService.serverConfig.webBaseUrl.absoluteString)
    XCTAssertEqual("en", env.apiService.language)
    XCTAssertEqual(UserFactory.user, env.currentUser)

    let differentEnv = AppEnvironment.fromStorage(ubiquitousStore: MockKeyValueStore(),
                                                  userDefaults: MockKeyValueStore())
    XCTAssertNil(differentEnv.apiService.oauthToken?.token)
    XCTAssertEqual(nil, differentEnv.currentUser)
  }

  func testFromStorage_WithOauthTokenStoredInUbiquitousStorage() {
    let userDefaults = MockKeyValueStore()
    let ubiquitousStore = MockKeyValueStore()
    ubiquitousStore.setObject("deadbeef", forKey: AppEnvironment.oauthTokenStorageKey)

    let env = AppEnvironment.fromStorage(ubiquitousStore: ubiquitousStore, userDefaults: userDefaults)

    XCTAssertEqual("deadbeef", env.apiService.oauthToken?.token)
    XCTAssertNil(env.currentUser)
  }

  func testSaveEnvironment() {
    let apiService = MockService(
      serverConfig: ServerConfig(
        apiBaseUrl: NSURL(string: "http://api.ksr.com")!,
        webBaseUrl: NSURL(string: "http://ksr.com")!,
        apiClientAuth: ClientAuth(clientId: "cafebeef"),
        basicHTTPAuth: nil
      ),
      oauthToken: OauthToken(token: "deadbeef")
    )
    let currentUser = UserFactory.user
    let userDefaults = MockKeyValueStore()
    let ubiquitousStore = MockKeyValueStore()

    AppEnvironment.saveEnvironment(environment: Environment(apiService: apiService, currentUser: currentUser),
                                   ubiquitousStore: ubiquitousStore,
                                   userDefaults: userDefaults)

    let result = userDefaults.dictionaryForKey(AppEnvironment.environmentStorageKey)!

    XCTAssertEqual("deadbeef", result["apiService.oauthToken.token"] as? String)
    XCTAssertEqual("http://api.ksr.com", result["apiService.serverConfig.apiBaseUrl"] as? String)
    XCTAssertEqual("cafebeef", result["apiService.serverConfig.apiClientAuth.clientId"] as? String)
    XCTAssertEqual("http://ksr.com", result["apiService.serverConfig.webBaseUrl"] as? String)
    XCTAssertEqual("en", result["apiService.language"] as? String)
    XCTAssertEqual(UserFactory.user.id, (result["currentUser"] as? [String:AnyObject])?["id"] as? Int)

    XCTAssertEqual("deadbeef", ubiquitousStore.stringForKey(AppEnvironment.oauthTokenStorageKey))
  }
}
