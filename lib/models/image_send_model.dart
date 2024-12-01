class ImageSendModel {
  String? status;
  int? statusCode;

  ImageSendModel({this.status, this.statusCode});

  ImageSendModel.fromJson(Map<String, dynamic> json) {
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
    return 'ImageSendModel(status: $status, statusCode: $statusCode)';
  }

}
