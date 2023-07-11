# Storage Billing Model

This model should help to decide the storage billing model to chose. Please see the official [Storage Billing Model](https://cloud.google.com/bigquery/docs/datasets-intro#dataset_storage_billing_models) documentation for details and eligibility.

Given the current [Pricing](https://cloud.google.com/bigquery/pricing#storage), physical storage is a little bit more than twice as expensive as locical billing and does charge extra for time travel. This means, only if the compression ratio for a dataset is reasonably high and exceeds 50%, a switch to physical billing can be considered.

Because, much higher compression ratios are rather common for large and flat analytics tables, configuring physical billing can safe a good amount of money.
