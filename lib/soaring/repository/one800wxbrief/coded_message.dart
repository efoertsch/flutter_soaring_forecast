class ReturnCodedMessage {
  String? code;
  String? message;

  ReturnCodedMessage({this.code, this.message});

  ReturnCodedMessage.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['message'] = this.message;
    return data;
  }
}
