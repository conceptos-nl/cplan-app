class ProfileModel {
  final bool success;
  final int notifications;
  final Customer customer;
  final InvoicesData invoices;
  final ScheduleData schedule;
  final List<Message> messages;

  ProfileModel({
    required this.success,
    required this.notifications,
    required this.customer,
    required this.invoices,
    required this.schedule,
    required this.messages,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      success: json['success'] ?? false,
      notifications: json['notifications'] ?? 0,
      customer: Customer.fromJson(json['customer'] ?? {}),
      invoices: InvoicesData.fromJson(json['invoices'] ?? {}),
      schedule: ScheduleData.fromJson(json['schedule'] ?? {}),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String address;
  final String number;
  final String floor;
  final String postal;
  final String city;
  final String lat;
  final String lng;
  final String phone;
  final String guid;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.number,
    required this.floor,
    required this.postal,
    required this.city,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.guid,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      number: json['number'] ?? '',
      floor: json['floor'] ?? '',
      postal: json['postal'] ?? '',
      city: json['city'] ?? '',
      lat: json['lat'] ?? '',
      lng: json['lng'] ?? '',
      phone: json['phone'] ?? '',
      guid: json['guid'] ?? '',
    );
  }
}

class InvoicesData {
  final List<Invoice> list;
  final String paymentUrl;
  final int totalOpenInvoices;
  final double totalOpenAmount;

  InvoicesData({
    required this.list,
    required this.paymentUrl,
    required this.totalOpenInvoices,
    required this.totalOpenAmount,
  });

  factory InvoicesData.fromJson(Map<String, dynamic> json) {
    return InvoicesData(
      list:
          (json['list'] as List<dynamic>?)
              ?.map((e) => Invoice.fromJson(e))
              .toList() ??
          [],
      paymentUrl: json['payment_url'] ?? '',
      totalOpenInvoices: json['total_open_invoices'] ?? 0,
      totalOpenAmount:
          double.tryParse(json['total_open_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Invoice {
  final String invoiceNo;
  final String dateInvoice;
  final double subtotal;
  final double vat;
  final double amount;
  final double amountPayed;
  final String status;
  final String paymentType;

  Invoice({
    required this.invoiceNo,
    required this.dateInvoice,
    required this.subtotal,
    required this.vat,
    required this.amount,
    required this.amountPayed,
    required this.status,
    required this.paymentType,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNo: json['invoice_no'] ?? '',
      dateInvoice: json['date_invoice'] ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      vat: double.tryParse(json['vat']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      amountPayed:
          double.tryParse(json['amount_payed']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      paymentType: json['payment_type'] ?? '',
    );
  }
}

class ScheduleData {
  final List<ScheduleItem> next;
  final List<ScheduleItem> appointments;

  ScheduleData({required this.next, required this.appointments});

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      next:
          (json['next'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e))
              .toList() ??
          [],
      appointments:
          (json['appointments'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ScheduleItem {
  final String date;
  final String title;
  final String status;
  final String statusColor;

  ScheduleItem({
    required this.date,
    required this.title,
    required this.status,
    required this.statusColor,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      statusColor: json['status_color'] ?? '',
    );
  }
}

class Message {
  final String id;
  final String subject;
  final String body;
  final String date;
  final String statusName;
  final String statusIcon;
  final String statusColor;
  final String typeName;
  final String typeIcon;
  final String seenStatus;
  final String readStatus;

  Message({
    required this.id,
    required this.subject,
    required this.body,
    required this.date,
    required this.statusName,
    required this.statusIcon,
    required this.statusColor,
    required this.typeName,
    required this.typeIcon,
    required this.seenStatus,
    required this.readStatus,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] ?? '',
      statusName: json['status_name'] ?? '',
      statusIcon: json['status_icon'] ?? '',
      statusColor: json['status_color'] ?? '',
      typeName: json['type_name'] ?? '',
      typeIcon: json['type_icon'] ?? '',
      seenStatus: json['status'] ?? '',
      readStatus: json['read'] ?? '',
    );
  }
}
