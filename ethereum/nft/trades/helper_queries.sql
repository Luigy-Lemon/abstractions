-- Sometimes the prices table is updated with a new token and tables like nft.trades
-- is not backfilled.
-- This query will find those missing prices and fill them
UPDATE
	nft.trades
SET
	usd_amount = new_prices.new_price
FROM
	(
		SELECT
			n.platform,
			n.tx_hash,
			n.trace_address,
			n.evt_index,
			n.trade_id,
			p.price as new_price
		FROM
			nft.trades n
			LEFT JOIN prices.usd p ON p.contract_address = n.currency_contract
			AND date_trunc('minute', n.block_time) = p."minute"
		WHERE
			usd_amount IS NULL
			AND p.symbol IS NOT NULL
	) as new_prices
where
	trades.platform = new_prices.platform
	AND trades.tx_hash = new_prices.tx_hash
	AND COALESCE(trades.trace_address, '{-1}') = COALESCE(new_prices.trace_address, '{-1}')
	AND COALESCE(trades.evt_index, -1) = COALESCE(new_prices.evt_index, -1)
	AND trades.trade_id = new_prices.trade_id;
