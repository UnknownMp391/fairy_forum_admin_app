String mapToQueryParameterString(Map<String, dynamic> params) {
  return params.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value.toString())}')
      .join('&');
}
