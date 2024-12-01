class OtpSentResponseModel {
  String? status;
  String? token;
  int? statusCode;

  OtpSentResponseModel({this.status, this.token, this.statusCode});

  OtpSentResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    statusCode = json['status_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['token'] = this.token;
    data['status_code'] = this.statusCode;
    return data;
  }

  @override
  String toString() {
    return 'OtpSentResponseModel{status: $status, token: $token, statusCode: $statusCode}';
  }
}
