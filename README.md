Domain Registrar
The Domain Registrar contract is a Clarity smart contract enabling decentralized domain registration and management on the Stacks blockchain.
It allows users to register unique domain names, manage ownership, and renew or reclaim expired domains securely on-chain.

Features
Decentralized domain registration
Ownership and transfer management
Expiration and renewal system
Transparent and event-logged actions
Prevention of duplicate registrations

Technical Overview
Language: Clarity
Core Functions:
register-domain – register a new unique domain
transfer-domain – transfer domain ownership
renew-domain – extend validity period
get-domain-info – view domain owner and expiry
reclaim-expired – reclaim expired domain names
Data Structure:
domains (map name → { owner: principal, expires_at: uint })
Logic:
Domain ownership expires after a set number of blocks unless renewed.
