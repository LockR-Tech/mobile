/// Văn bản pháp lý (`assets/markdown/*.md`) tách thành phần để trang hiển thị dựng thẻ riêng từng mục.
///
/// Định dạng file: `# Tiêu đề`, đoạn đầu là dòng phiên bản, các đoạn sau là lời mở đầu, rồi các mục
/// `## 1. Tên mục`. Tách theo dòng, không cần trình phân tích markdown đầy đủ.
class LegalText {
  const LegalText({
    required this.title,
    required this.meta,
    required this.intro,
    required this.sections,
  });

  final String title;

  /// Dòng "Phiên bản … · Áp dụng cho …" ngay dưới tiêu đề.
  final String meta;

  /// Markdown giữa dòng phiên bản và mục đầu tiên.
  final String intro;
  final List<LegalSection> sections;

  factory LegalText.parse(String markdown) {
    var title = '';
    final preamble = <String>[];
    final sections = <LegalSection>[];
    String? heading;
    var body = <String>[];

    void closeSection() {
      final h = heading;
      if (h == null) return;
      sections.add(
        LegalSection.fromHeading(
          h,
          body.join('\n').trim(),
          sections.length + 1,
        ),
      );
    }

    for (final line in markdown.replaceAll('\r\n', '\n').split('\n')) {
      if (line.startsWith('## ')) {
        closeSection();
        heading = line.substring(3).trim();
        body = <String>[];
      } else if (line.startsWith('# ') && title.isEmpty && heading == null) {
        title = line.substring(2).trim();
      } else if (heading == null) {
        preamble.add(line);
      } else {
        body.add(line);
      }
    }
    closeSection();

    final paragraphs = preamble
        .join('\n')
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return LegalText(
      title: title,
      meta: paragraphs.isEmpty ? '' : paragraphs.first,
      intro: paragraphs.skip(1).join('\n\n'),
      sections: sections,
    );
  }
}

class LegalSection {
  const LegalSection({
    required this.number,
    required this.title,
    required this.body,
  });

  /// Lấy số trong tiêu đề `## 3. Hàng gửi`; tiêu đề không đánh số thì dùng thứ tự mục.
  factory LegalSection.fromHeading(String heading, String body, int position) {
    final match = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(heading);
    return LegalSection(
      number: match?.group(1) ?? '$position',
      title: match?.group(2) ?? heading,
      body: body,
    );
  }

  final String number;
  final String title;
  final String body;
}
