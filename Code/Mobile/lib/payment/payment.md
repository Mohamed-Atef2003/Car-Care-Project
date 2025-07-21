# نظام الدفع في تطبيق Car Care

## المكونات الرئيسية

يتكون نظام الدفع في تطبيق Car Care من عدة مكونات متكاملة تعمل معًا لتوفير تجربة دفع سلسة وآمنة:

1. **مدير الدفع (PaymobManager)**: المسؤول عن التكامل مع بوابة الدفع Paymob وإدارة عمليات الدفع.
2. **شاشة تفاصيل الدفع (PaymentDetailsScreen)**: واجهة المستخدم الرئيسية لعرض تفاصيل الطلب واختيار طريقة الدفع.
3. **معالج الروابط العميقة (DeepLinkHandler)**: يتعامل مع استقبال نتائج عمليات الدفع عبر الروابط العميقة.
4. **طرق الدفع المختلفة**: مثل الدفع عند الاستلام والدفع الإلكتروني وغيرها.
5. **واجهات عرض النجاح والفشل**: لعرض نتيجة عملية الدفع بطريقة سهلة وواضحة.

## تدفق عملية الدفع

### 1. بدء عملية الدفع

```
المستخدم --> PaymentDetailsScreen --> اختيار طريقة الدفع --> معالجة الدفع --> استلام النتيجة
```

عندما يبدأ المستخدم عملية الدفع:
- يتم عرض تفاصيل الطلب والمبلغ الإجمالي على شاشة `PaymentDetailsScreen`
- يمكن للمستخدم تطبيق كود خصم إذا كان متاحًا
- يختار المستخدم طريقة الدفع المفضلة (بطاقة، محفظة إلكترونية، دفع عند الاستلام)
- تتم معالجة الدفع وفقًا للطريقة المختارة

### 2. معالجة الدفع عبر Paymob

عند اختيار الدفع الإلكتروني (بطاقة أو محفظة)، تتم العملية على النحو التالي:

1. **الحصول على رمز المصادقة (Authentication Token)**:
   ```dart
   String token = await postToken();
   ```

2. **تسجيل الطلب في نظام Paymob**:
   ```dart
   int registeredOrderId = await postOrder(token: token, amount: amountInCents.toString());
   ```

3. **إنشاء مفتاح الدفع**:
   ```dart
   String paymentKey = await getPaymentKey(
     context: context, 
     token: token, 
     orderId: registeredOrderId.toString(), 
     amount: amountInCents.toString()
   );
   ```

4. **توجيه المستخدم إلى صفحة الدفع**:
   - في حالة الدفع بالبطاقة: يتم فتح صفحة الدفع في WebView
   - في حالة المحفظة الإلكترونية: يتم إعداد رابط الدفع وإرساله للمستخدم

### 3. استقبال نتيجة الدفع

بعد إكمال المستخدم لعملية الدفع:
- يتم إعادة توجيه المستخدم إلى التطبيق عبر رابط عميق (deep link)
- يقوم `DeepLinkHandler` باستقبال الرابط ومعالجته
- يتم التحقق من نتيجة العملية (نجاح/فشل)
- يتم عرض شاشة نجاح أو فشل الدفع وفقًا للنتيجة

## طرق الدفع المتاحة

### 1. الدفع عند الاستلام (Cash Collection)

- لا يتطلب معالجة فورية للدفع
- يتم تسجيل الطلب وإرساله للتنفيذ
- يقوم المستخدم بالدفع عند استلام المنتج/الخدمة

```dart
// تنفيذ طلب الدفع عند الاستلام
Future<void> processCashOnDelivery() async {
  // إنشاء سجل معاملة دفع
  final transaction = PaymentTransaction(
    transactionId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
    amount: widget.paymentSummary.total,
    currency: widget.paymentSummary.currency,
    timestamp: DateTime.now(),
    paymentMethod: 'cash_collection',
    success: true,
    orderId: widget.orderId ?? '',
    additionalData: {
      'notes': _notesController.text,
      'address': _addressController.text,
    },
  );
  
  // تحديث حالة الطلب
  // حفظ المعاملة
}
```

### 2. الدفع بالبطاقة (Card Payment)

- يتطلب تكامل مع بوابة الدفع Paymob
- يتم توجيه المستخدم إلى صفحة الدفع الآمنة
- يتم استلام نتيجة الدفع عبر رابط عميق

```dart
// بدء عملية الدفع بالبطاقة
Future<void> processCardPayment() async {
  final paymentKey = await _paymobManager.payWithPaymob(
    context: context,
    amount: widget.paymentSummary.total,
    orderId: widget.orderId ?? '',
  );
  
  // فتح صفحة الدفع في WebView
  launchCardPaymentScreen(paymentKey);
}
```

### 3. الدفع بالمحفظة الإلكترونية (Mobile Wallet)

- يتطلب تكامل مع Paymob ومعرفة رقم الهاتف للمستخدم
- يتم إنشاء طلب دفع وإرساله للمستخدم عبر المحفظة
- يتم استلام نتيجة الدفع عبر رابط عميق

```dart
// بدء عملية الدفع بالمحفظة الإلكترونية
Future<void> processWalletPayment() async {
  final paymentKey = await _paymobManager.payWithPaymob(
    context: context,
    amount: widget.paymentSummary.total,
    orderId: widget.orderId ?? '',
    integrationType: 'wallet',
  );
  
  // إرسال طلب الدفع للمحفظة
  launchWalletPayment(paymentKey);
}
```

## معالجة استجابة الدفع

عندما يتلقى التطبيق نتيجة الدفع عبر الرابط العميق:

```dart
static void _handleDeepLink(String link, BuildContext context) {
  if (link.contains('carcare://')) {
    Uri uri = Uri.parse(link);
    
    // معالجة نتيجة الدفع
    final paymentResult = PaymobManager.processPaymentResult(uri);
    
    if (paymentResult != null) {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      paymentProvider.setPaymentTransaction(paymentResult);
      
      // عرض رسالة نجاح أو فشل
      if (paymentResult.success) {
        _showPaymentResultDialog(context, true, paymentResult);
      } else {
        _showPaymentResultDialog(context, false, paymentResult);
      }
    }
  }
}
```

## نماذج البيانات (Data Models)

### 1. نموذج معاملة الدفع (PaymentTransaction)

```dart
class PaymentTransaction {
  final String transactionId;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final String paymentMethod;
  final bool success;
  final String? error;
  final Map<String, dynamic>? additionalData;
  final String orderId;
  
  // ... المزيد من التفاصيل
}
```

### 2. نموذج ملخص الدفع (PaymentSummary)

```dart
class PaymentSummary {
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String currency;
  final List<Map<String, dynamic>>? items;
  
  // ... المزيد من التفاصيل
}
```

## معالجة الخصومات

يدعم النظام تطبيق الخصومات على الطلبات من خلال:

1. **أكواد الخصم المدخلة**:
   - يمكن للمستخدم إدخال كود خصم
   - يتم التحقق من صلاحية الكود والحد الأدنى للطلب
   - يتم تطبيق الخصم على إجمالي الطلب

2. **أنواع الخصومات المدعومة**:
   - نسبة مئوية من إجمالي الطلب
   - مبلغ ثابت
   - خصم على رسوم التوصيل

```dart
// تطبيق كود خصم
void applyDiscountCode(String code) {
  // البحث عن الكود في قاعدة البيانات
  final discountCode = _availableDiscountCodes.firstWhere(
    (discount) => discount['code'] == code.toUpperCase(),
    orElse: () => {},
  );
  
  if (discountCode.isEmpty) {
    _discountError = 'كود الخصم غير صالح';
    return;
  }
  
  // التحقق من الحد الأدنى للطلب
  if (widget.paymentSummary.subtotal < discountCode['minOrderValue']) {
    _discountError = 'الحد الأدنى للطلب ${discountCode['minOrderValue']} ${widget.paymentSummary.currency}';
    return;
  }
  
  // حساب قيمة الخصم
  double discountAmount = 0.0;
  if (discountCode['type'] == 'percentage') {
    discountAmount = widget.paymentSummary.subtotal * discountCode['value'];
  } else if (discountCode['type'] == 'fixed') {
    discountAmount = discountCode['value'];
  } else if (discountCode['type'] == 'shipping') {
    discountAmount = widget.paymentSummary.deliveryFee * discountCode['value'];
  }
  
  _appliedDiscountAmount = discountAmount;
  _appliedDiscountCode = code;
  _discountError = null;
  
  // تحديث إجمالي الطلب
  updateOrderTotal();
}
```

## تأكيد الطلب وإكمال الدفع

عند تأكيد الطلب:

1. **تحقق من صحة المعلومات**:
   - تأكد من صحة العنوان ومعلومات التوصيل
   - تأكد من صحة طريقة الدفع المختارة

2. **معالجة الدفع**:
   - تنفيذ عملية الدفع وفقًا للطريقة المختارة
   - الانتظار حتى اكتمال عملية الدفع

3. **تحديث حالة الطلب**:
   - تحديث حالة الطلب في قاعدة البيانات
   - توجيه المستخدم إلى شاشة تأكيد نجاح الطلب

## ميزات الأمان

يتضمن نظام الدفع عدة ميزات أمان:

1. **تخزين آمن لبيانات الدفع**:
   - لا يتم تخزين بيانات البطاقة في التطبيق
   - يتم استخدام بوابة Paymob الآمنة لمعالجة البطاقات

2. **مصادقة آمنة**:
   - استخدام رموز API المشفرة
   - استخدام رموز المصادقة المؤقتة

3. **معالجة الاستجابة**:
   - التحقق من صحة الاستجابة من بوابة الدفع
   - مصادقة نتائج الدفع قبل تأكيد الطلب

## ملخص

يوفر نظام الدفع في تطبيق Car Care تجربة دفع متكاملة وآمنة من خلال:
- تكامل سلس مع بوابة الدفع Paymob
- دعم متعدد لطرق الدفع (بطاقات، محافظ إلكترونية، دفع عند الاستلام)
- واجهة مستخدم سهلة وبسيطة لإدارة عملية الدفع
- معالجة آمنة لبيانات الدفع
- نظام فعال لتطبيق الخصومات
- تأكيد فوري لنتائج الدفع

يمكن تطوير النظام مستقبلاً من خلال:
- إضافة المزيد من بوابات الدفع
- دعم المزيد من العملات
- تحسين تتبع معاملات الدفع
- إضافة برنامج ولاء ونقاط للمستخدمين 