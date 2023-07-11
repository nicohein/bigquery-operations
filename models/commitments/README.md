# Commitments

In the the capacity based [pricing model](https://cloud.google.com/bigquery/pricing#analysis_pricing_models) Google gives a discount of 20% for 1 year commitments and a 40% discount for 3 year comittments

This means that comittments protentially pay off finacially, if the slots are used more than 60% or respectively 80% of the time. There are additional considerations to be made, wich include for exmample performance. Everyone making decisions for or against a comittement should weight all relevant factors for their organization. These dbt models can only assist in the decision making process.

To answer this overlimplified question if comittments protentially pay off financially, I have created two models:

1. `slots_per_second` showing the actual slots used per second and
2. `slot_coverage` shoing the slot coverage given different baselines

I decided to calculate the slot usage on a second by second even even though autoscaler slots are hold for a full minute. The reason is that the autoscaler does not scale up at full minute intervals. When interpreting the results, calculate the autoscaler overhead for your project (soon to be added to this project) to get a better idea of tha actual financial imapct.
