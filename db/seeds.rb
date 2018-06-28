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
	{ name: "True North Seedbank\nTNSB (Phone Orders)\nTNSB (Phone Orders)" },
	{ name: "True North Seedbank\nTrue North Seedbank\nTrue North Seedbank" },
	{ name: "True North Seedbank\nTrue North Seedbank\nFrench" },
	{ name: "TNSB (Mail Orders)\nTNSB (Mail Orders)\nTNSB (Mail Orders)" },
	{ name: "CC Nexus\nCC Nexus\nCC Nexus" },
	{ name: "CC Nexus\nCC Nexus\nFrench" },
	{ name: "Canuk Seeds\nCanuk Seeds\nFrench" },
	{ name: "Canuk Seeds\nCanuk Seeds\nCanuk Seeds" },
	{ name: "Oasis Genetics\nOasis Genetics\nOasis Genetics" },
	{ name: "Store\nStore\nStore 1" },
	{ name: "Store\nStore\nStore 2" },
	{ name: "Store\nStore\nStore 3" },
	{ name: "Store\nStore\nStore 4" },
])

