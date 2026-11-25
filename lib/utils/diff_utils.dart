enum DiffOp { equal, insert, delete }

class DiffLine {
  const DiffLine(this.op, this.leftLineNo, this.rightLineNo, this.text);
  final DiffOp op;
  final int? leftLineNo;
  final int? rightLineNo;
  final String text;
}

class DiffUtils {
  /// Line-level diff using Longest Common Subsequence.
  ///
  /// Returns a flat list of operations in source order. Each output line is
  /// tagged with its line number on the left and/or right side so the UI can
  /// render aligned gutters.
  static List<DiffLine> lineDiff(String left, String right) {
    final a = left.isEmpty ? <String>[] : left.split('\n');
    final b = right.isEmpty ? <String>[] : right.split('\n');

    // LCS length DP table.
    final n = a.length, m = b.length;
    final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (int i = n - 1; i >= 0; i--) {
      for (int j = m - 1; j >= 0; j--) {
        if (a[i] == b[j]) {
          lcs[i][j] = lcs[i + 1][j + 1] + 1;
        } else {
          lcs[i][j] =
              lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1];
        }
      }
    }

    final result = <DiffLine>[];
    int i = 0, j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        result.add(DiffLine(DiffOp.equal, i + 1, j + 1, a[i]));
        i++;
        j++;
      } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        result.add(DiffLine(DiffOp.delete, i + 1, null, a[i]));
        i++;
      } else {
        result.add(DiffLine(DiffOp.insert, null, j + 1, b[j]));
        j++;
      }
    }
    while (i < n) {
      result.add(DiffLine(DiffOp.delete, i + 1, null, a[i]));
      i++;
    }
    while (j < m) {
      result.add(DiffLine(DiffOp.insert, null, j + 1, b[j]));
      j++;
    }
    return result;
  }

  /// Keeps changes and nearby equal rows in their original order.
  static List<DiffLine> withChangeContext(List<DiffLine> diff,
      { int context = 3 }) {
        RangeError.checkNotNegative(context, 'context');
    final result = <DiffLine>[];
    var nextChange = 0;
    var previousChange = -context - 1;

    for (int i = 0; i < diff.length; i++) {
      if (nextChange < i) nextChange = i;
      while (nextChange < diff.length && diff[nextChange].op == DiffOp.equal) {
        nextChange++;
      }
      if (diff[i].op != DiffOp.equal) previousChange = i;
      final nearPrevious = i - previousChange <= context;
      final nearNext = nextChange < diff.length && nextChange - i <= context;
      if (nearPrevious || nearNext) result.add(diff[i]);
    }
    return result;
  }

  /// Quick summary numbers for a finished diff.
  static ({int added, int removed, int unchanged}) stats(List<DiffLine> diff) {
    int added = 0, removed = 0, unchanged = 0;
    for (final d in diff) {
      switch (d.op) {
        case DiffOp.insert:
          added++;
        case DiffOp.delete:
          removed++;
        case DiffOp.equal:
          unchanged++;
      }
    }
    return (added: added, removed: removed, unchanged: unchanged);
  }
}
