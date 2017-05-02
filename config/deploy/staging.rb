set :stage, :staging
server 'magentoqbo-staging.rotati.com', user: 'deployer', roles: %w{app web db}
