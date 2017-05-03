set :stage, :production
server 'magentoqbo.rotati.com', user: 'deployer', roles: %w{app web db}
