class NumberResponseModel {
  String? status;
  int? statusCode;

  NumberResponseModel({this.status, this.statusCode});

  NumberResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    statusCode = json['status_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['status_code'] = this.statusCode;
    return data;
  }

  @override
  String toString() {
    return '{status: $status, statusCode: $statusCode}';
  }

}
