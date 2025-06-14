import Foundation

/// 画像キャッシュのプロトコル
public protocol StorageImageCacheProtocol: Sendable {
  /// 画像URLを取得する（キャッシュがあればキャッシュから、なければStorageClientから）
  func getImageURL(for path: String) async throws -> URL

  /// キャッシュをクリアする
  func clearCache() async
}

/// 画像データをローカルにキャッシュするためのクライアント
public final actor StorageImageCache: StorageImageCacheProtocol {
  public static let shared: any StorageImageCacheProtocol = StorageImageCache()

  private var cache: [String: URL] = [:]
  private let storageClient: StorageClient
  private let fileManager = FileManager.default

  public init(storageClient: StorageClient = DefaultStorageClient()) {
    self.storageClient = storageClient
    Task {
      await createCacheDirectoryIfNeeded()
    }
  }

  /// 画像URLを取得する（キャッシュがあればキャッシュから、なければStorageClientから）
  public func getImageURL(for path: String) async throws -> URL {
    // キャッシュにあればそれを返す
    if let cachedURL = cache[path], fileManager.fileExists(atPath: cachedURL.path) {
      return cachedURL
    }

    // ローカルにファイルが保存済みか確認
    let cacheDirectory = try getCacheDirectory()
    let fileName = path.replacingOccurrences(of: "/", with: "_")
    let fileURL = cacheDirectory.appendingPathComponent(fileName)

    if fileManager.fileExists(atPath: fileURL.path) {
      // ファイルが存在する場合はそのURLをキャッシュに保存して返す
      cache[path] = fileURL
      return fileURL
    }

    // ローカルになければStorageClientからダウンロードしてローカルに保存
    let storageURL = try await storageClient.url(path)
    let localURL = try await downloadAndSaveImage(from: storageURL, for: path)

    // キャッシュに保存
    cache[path] = localURL
    return localURL
  }

  /// 画像をダウンロードしてローカルに保存する
  private func downloadAndSaveImage(from url: URL, for path: String) async throws -> URL {
    let cacheDirectory = try getCacheDirectory()
    let fileName = path.replacingOccurrences(of: "/", with: "_")
    let fileURL = cacheDirectory.appendingPathComponent(fileName)

    // すでにファイルが存在する場合は削除
    if fileManager.fileExists(atPath: fileURL.path) {
      try fileManager.removeItem(at: fileURL)
    }

    // URLSessionを使って画像をダウンロード
    let (data, _) = try await URLSession.shared.data(from: url)

    // ファイルに保存
    try data.write(to: fileURL)

    return fileURL
  }

  /// キャッシュディレクトリを取得する
  private func getCacheDirectory() throws -> URL {
    let cacheDirectory = try fileManager.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("StorageImageCache", isDirectory: true)

    return cacheDirectory
  }

  /// キャッシュディレクトリを作成する
  private func createCacheDirectoryIfNeeded() async {
    do {
      let cacheDirectory = try getCacheDirectory()
      if !fileManager.fileExists(atPath: cacheDirectory.path) {
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
      }
    } catch {
      print("Failed to create cache directory: \(error.localizedDescription)")
    }
  }

  /// キャッシュをクリアする
  public func clearCache() async {
    cache.removeAll()

    do {
      let cacheDirectory = try getCacheDirectory()
      let contents = try fileManager.contentsOfDirectory(
        at: cacheDirectory, includingPropertiesForKeys: nil)

      for fileURL in contents {
        try fileManager.removeItem(at: fileURL)
      }
    } catch {
      print("Failed to clear cache: \(error.localizedDescription)")
    }
  }
}
