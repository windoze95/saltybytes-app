/// Links into the public website (saltybytes.ai) — the shareable, no-account
/// surface. Distinct from ApiEndpoints, which is strictly the API host.
class WebLinks {
  WebLinks._();

  static const String siteBase = 'https://saltybytes.ai';

  /// The public web page for a recipe extracted from [sourceUrl]. The site
  /// resolves the URL against the extraction cache and renders the recipe
  /// with an open-in-app banner, so this is the link to put in share sheets.
  static String recipePage(String sourceUrl) =>
      '$siteBase/r?u=${Uri.encodeQueryComponent(sourceUrl)}';
}
