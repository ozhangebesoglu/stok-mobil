import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/date_formatter.dart';

// Bu widget'ın state'e ihtiyacı olacak çünkü kendi form elemanlarını yönetecek.
// Ancak şimdilik ana state'ten beslenecek şekilde tasarlayalım.
// Daha sonra bunu kendi StatefulWidget'ına dönüştürebiliriz.

class RestaurantSalesTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController restaurantController;
  final TextEditingController amountController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController notesController;
  final List<Map<String, dynamic>> restaurantSales;
  final VoidCallback onAddSale;
  final Function(int) onDeleteSale;
  final Function(Map<String, dynamic>) onEditSale;
  final VoidCallback onClearForm;
  final Widget productDropdown;
  final Widget unitDropdown;
  final bool isEditing;

  const RestaurantSalesTab({
    super.key,
    required this.formKey,
    required this.restaurantController,
    required this.amountController,
    required this.quantityController,
    required this.unitPriceController,
    required this.notesController,
    required this.restaurantSales,
    required this.onAddSale,
    required this.onDeleteSale,
    required this.onEditSale,
    required this.onClearForm,
    required this.productDropdown,
    required this.unitDropdown,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRestaurantSaleForm(context),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            "Geçmiş Restoran Satışları",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildRestaurantSalesList(),
        ],
      ),
    );
  }

  Widget _buildRestaurantSaleForm(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: restaurantController,
            decoration: const InputDecoration(
              labelText: 'Restoran Adı *',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
          ),
          const SizedBox(height: 10),
          productDropdown,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: unitDropdown),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: unitPriceController,
            decoration: const InputDecoration(
              labelText: 'Birim Fiyat (₺)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Toplam Tutar (₺) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator:
                (value) =>
                    value!.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) <= 0
                        ? 'Geçerli bir tutar girin'
                        : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notlar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isEditing)
                TextButton(onPressed: onClearForm, child: const Text("İptal")),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onAddSale,
                child: Text(isEditing ? 'Güncelle' : 'Ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantSalesList() {
    if (restaurantSales.isEmpty) {
      return const Center(child: Text("Henüz restoran satışı yok."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: restaurantSales.length,
      itemBuilder: (context, index) {
        final sale = restaurantSales[index];
        final displayDate = DateFormatter.formatDisplayDate(sale['date']);

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.restaurant, color: Colors.white, size: 20.w),
            ),
            title: Text(
              sale['restaurant'],
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  '${sale['productName']} - ${sale['quantity']} ${sale['unit']}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  displayDate,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '${sale['amount']} ₺',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ),
            isThreeLine: true,
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(sale['restaurant']),
                      content: Text(
                        "Bu satışı düzenlemek veya silmek istiyor musunuz?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onEditSale(sale);
                          },
                          child: const Text("Düzenle"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDeleteSale(sale['id']);
                          },
                          child: const Text(
                            "Sil",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        );
      },
    );
  }
}
