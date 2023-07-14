/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
*/

/* *****************************************************************************
 * -------------------------------Referencce------------------------------------
 * This script is the demo script of Hyperledger Fabric network and we do some
 * modifications on the script so that it suits better in our project.
 *
 * Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
 * *****************************************************************************
*/

'use strict';
const stringify  = require('json-stringify-deterministic');
const sortKeysRecursive  = require('sort-keys-recursive');

const {Contract} = require('fabric-contract-api');

class Chaincode extends Contract {

	// CreateAsset - create a new asset, store into chaincode state
	async CreateAsset(ctx, id, type, data) {
		const exists = await this.AssetExists(ctx, id);
		if (exists) {
			throw new Error(`The asset ${id} already exists`);
		}

		// ==== Create asset object and marshal to JSON ====
		const json_data = JSON.parse(data);

		let asset = {
			id:id,
			type: type,
			data: json_data,
		};


		// === Save asset to state ===
		await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(asset))));
		//await ctx.stub.putState(id, Buffer.from(JSON.stringify(asset)));
		let indexName = 'type-index';
		let indexKey = await ctx.stub.createCompositeKey(indexName, [asset.type, asset.id]);

		//  Save index entry to state. Only the key name is needed, no need to store a duplicate copy of the marble.
		//  Note - passing a 'nil' value will effectively delete the key from state, therefore we pass null character as value
		await ctx.stub.putState(indexKey, Buffer.from('\u0000'));
		return asset;
	}

	// ReadAsset returns the asset stored in the world state with given id.
	async ReadAsset(ctx, id) {
		const assetJSON = await ctx.stub.getState(id); // get the asset from chaincode state
		if (!assetJSON || assetJSON.length === 0) {
			throw new Error(`Asset ${id} does not exist`);
		}

		return assetJSON.toString();
	}




	// GetAssetsByRange performs a range query based on the start and end keys provided.
	// Read-only function results are not typically submitted to ordering. If the read-only
	// results are submitted to ordering, or if the query is used in an update transaction
	// and submitted to ordering, then the committing peers will re-execute to guarantee that
	// result sets are stable between endorsement time and commit time. The transaction is
	// invalidated by the committing peers if the result set has changed between endorsement
	// time and commit time.
	// Therefore, range queries are a safe option for performing update transactions based on query results.
	async GetAssetsByRange(ctx, startKey, endKey) {

		let resultsIterator = await ctx.stub.getStateByRange(startKey, endKey);
		let results = await this._GetAllResults(resultsIterator, false);

		return JSON.stringify(results);
	}

	// TransferAssetByColor will transfer assets of a given color to a certain new owner.
	// Uses a GetStateByPartialCompositeKey (range query) against color~name 'index'.
	// Committing peers will re-execute range queries to guarantee that result sets are stable
	// between endorsement time and commit time. The transaction is invalidated by the
	// committing peers if the result set has changed between endorsement time and commit time.
	// Therefore, range queries are a safe option for performing update transactions based on query results.
	// Example: GetStateByPartialCompositeKey/RangeQuery
	


	// AssetExists returns true when asset with given ID exists in world state
	async AssetExists(ctx, id) {
		// ==== Check if asset already exists ====
		let assetState = await ctx.stub.getState(id);
		return assetState && assetState.length > 0;
	}

	// This is JavaScript so without Funcation Decorators, all functions are assumed
	// to be transaction functions
	//
	// For internal functions... prefix them with _
	async _GetAllResults(iterator, isHistory) {
		let allResults = [];
		let res = await iterator.next();
		while (!res.done) {
			if (res.value && res.value.value.toString()) {
				let jsonRes = {};
				console.log(res.value.value.toString('utf8'));
				if (isHistory && isHistory === true) {
					jsonRes.TxId = res.value.txId;
					jsonRes.Timestamp = res.value.timestamp;
					try {
						jsonRes.Value = JSON.parse(res.value.value.toString('utf8'));
					} catch (err) {
						console.log(err);
						jsonRes.Value = res.value.value.toString('utf8');
					}
				} else {
					jsonRes.Key = res.value.key;
					try {
						jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
					} catch (err) {
						console.log(err);
						jsonRes.Record = res.value.value.toString('utf8');
					}
				}
				allResults.push(jsonRes);
			}
			res = await iterator.next();
		}
		iterator.close();
		return allResults;
	}

	// InitLedger creates sample assets in the ledger
	async InitLedger(ctx) {
		const asset = {
			id: '0',
			type: 'Test Doc 1',
			data: {
				vendorId: '1',
				description: 'Testing entity',
			}
		};

		await ctx.stub.putState(asset.id, Buffer.from(stringify(sortKeysRecursive(asset))));
	}
}

module.exports = Chaincode;
