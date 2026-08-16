sealed class ParseResult<T> {
  const ParseResult();
}

class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess(this.value);

  final T value;
}

class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure(this.message);

  final String message;
}
