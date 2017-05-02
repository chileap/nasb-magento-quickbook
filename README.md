[ ![Codeship Status for rotati/nasb-magento-quickbooks](https://codeship.com/projects/d2e62550-7cd7-0134-501d-369b6cd4ca27/status?branch=master)](https://codeship.com/projects/181201)

# README

NASB Magento <-> QuickBooks Integration

### Requirements

* Ruby > 2.3.x
* Rails 5.x

### Setup

```
git clone git@github.com:rotati/nasb-magento-quickbooks.git

cd nasb-magento-quickbooks

bundle install
rake db:create
rake db:migrate
```

### Running

To run rails app:

```
rails s
```

To run script rake task of pushing invoice to Qbo:

```
bundle exec rake magento_quickbooks_integrator:pushing_orders_to_qbo
```

To run script rake task of pushing tax from staging to production Qbo:

```
bundle exec rake magento_quickbooks_integrator:push_all_tax_code
```

To delete sales receipt in QBO:

```
bundle exec rake magento_quickbooks_integrator:delete_sales_reciept_by_month
```
