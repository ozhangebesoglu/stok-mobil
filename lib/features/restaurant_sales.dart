import 'package:flutter/material.dart';

class RestaurantSalesPage extends StatefulWidget {
  const RestaurantSalesPage({super.key});

  @override
  State<RestaurantSalesPage> createState() => _RestaurantSalesPageState();
}

class _RestaurantSalesPageState extends State<RestaurantSalesPage> {
  final List<Map<String, dynamic>> sales = [];
  final TextEditingController restaurantController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  void addSale() {
    final restaurantName = restaurantController.text;
    final amount = double.tryParse(amountController.text) ?? 0;

    if (restaurantName.isEmpty || amount <= 0) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              content: Text('Geçerli bir restoran ismi ve tutar girin!'),
            ),
      );
      return;
    }

    setState(() {
      sales.add({'restaurant': restaurantName, 'amount': amount});
    });
    restaurantController.clear();
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD2B48C),
      appBar: AppBar(title: Text('Restoranlara Satış')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: restaurantController,
              decoration: InputDecoration(
                labelText: 'Restoran İsmi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Satış Tutarı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: addSale, child: Text('Satış Ekle')),
            Expanded(
              child: ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  return ListTile(
                    title: Text(sale['restaurant']),
                    subtitle: Text(
                      'Tutar: ${sale['amount'].toStringAsFixed(2)} ₺',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
