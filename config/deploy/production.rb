set :stage, :production
server '54.149.183.55', user: 'deployer', roles: %w{app web db}
