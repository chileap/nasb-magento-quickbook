# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

State.create([
	{ name: "Canceled" },
	{ name: "Closed" },
	{ name: "Complete" },
	{ name: "Complete - Chargeback" },
	{ name: "Suspected Fraud" },
	{ name: "On Hold" },
	{ name: "On Hold - No Reservation" },
	{ name: "Payment Review" },
	{ name: "PayPal Canceled Reversal" },
	{ name: "PayPal Reversed" },
	{ name: "Pending" },
	{ name: "Pending - Bitcoin" },
	{ name: "Pending - Bitcoin" },
	{ name: "Pending - BT" },
	{ name: "Pending - Cash" },
	{ name: "Pending - eT" },
	{ name: "Pending - Card Failed" },
	{ name: "Pending - Card Ver Form" },
	{ name: "Pending - MO" },
	{ name: "Pending - New" },
	{ name: "Pending Payment" },
	{ name: "Pending PayPal" },
	{ name: "Pending - PayPal Invoiced" },
	{ name: "Pending - PayPal" },
	{ name: "Processing" },
	{ name: "Processing (Printed" },
	{ name: "Processing (Printed CA" },
	{ name: "Processing - To Resolve" },
])

Store.create([
	{ name: 'True North Seedbank&nbsp;&nbsp;&nbsp;&nbsp;TNSB (Phone Orders)&nbsp;&nbsp;&nbsp;&nbsp;TNSB (Phone Orders)' },
	{ name: 'True North Seedbank&nbsp;&nbsp;&nbsp;&nbsp;True North Seedbank&nbsp;&nbsp;&nbsp;&nbsp;True North Seedbank' },
	{ name: 'True North Seedbank&nbsp;&nbsp;&nbsp;&nbsp;True North Seedbank&nbsp;&nbsp;&nbsp;&nbsp;French' },
	{ name: 'TNSB (Mail Orders)&nbsp;&nbsp;&nbsp;&nbsp;TNSB (Mail Orders)&nbsp;&nbsp;&nbsp;&nbsp;TNSB (Mail Orders)' },
	{ name: 'CC Nexus&nbsp;&nbsp;&nbsp;&nbsp;CC Nexus&nbsp;&nbsp;&nbsp;&nbsp;CC Nexus' },
	{ name: 'CC Nexus&nbsp;&nbsp;&nbsp;&nbsp;CC Nexus&nbsp;&nbsp;&nbsp;&nbsp;French' },
	{ name: 'Canuk Seeds&nbsp;&nbsp;&nbsp;&nbsp;Canuk Seeds&nbsp;&nbsp;&nbsp;&nbsp;French' },
	{ name: 'Canuk Seeds&nbsp;&nbsp;&nbsp;&nbsp;Canuk Seeds&nbsp;&nbsp;&nbsp;&nbsp;Canuk Seeds' },
	{ name: 'Oasis Genetics&nbsp;&nbsp;&nbsp;&nbsp;Oasis Genetics&nbsp;&nbsp;&nbsp;&nbsp;Oasis Genetics' },
	{ name: 'Store&nbsp;&nbsp;&nbsp;&nbsp;Store&nbsp;&nbsp;&nbsp;&nbsp;Store 1' },
	{ name: 'Store&nbsp;&nbsp;&nbsp;&nbsp;Store&nbsp;&nbsp;&nbsp;&nbsp;Store 2' },
	{ name: 'Store&nbsp;&nbsp;&nbsp;&nbsp;Store&nbsp;&nbsp;&nbsp;&nbsp;Store 3' },
	{ name: 'Store&nbsp;&nbsp;&nbsp;&nbsp;Store&nbsp;&nbsp;&nbsp;&nbsp;Store 4' },
])

