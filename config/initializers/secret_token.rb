# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Crosswords::Application.config.secret_token = ENV['SECRET_TOKEN'] || '23971fce09f701c42949d73b3fb06bd90b592d81aac9db9b726e953ae4a76c432f1871be4d88d82ddcd4beffea01c4fe674b6da8b53ae66c9ae43d342b499755'
