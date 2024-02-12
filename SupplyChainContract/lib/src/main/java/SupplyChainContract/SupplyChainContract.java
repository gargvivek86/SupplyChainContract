package SupplyChainContract;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import com.owlike.genson.Genson;

// Contract annotation defines the contract name and provides information about the contract
@Contract(name = "SupplyChainContract", info = @Info(title = "Supply Chain Contract", description = "A sample Hyperledger Fabric Java Smart Contract for supply chain management"))
@Default
public final class SupplyChainContract implements ContractInterface {

	private final Genson genson = new Genson();

	// Method to initialize the ledger with sample data
	@Transaction()
	public void initLedger(final Context ctx) {

	}

	// Transaction method to record the movement of a product in the supply chain
	@Transaction
	public Product addProduct(final Context ctx, String productID, String name, String producer) {

		ChaincodeStub stub = ctx.getStub();

		String productState = stub.getStringState(productID);
		if (!productState.isEmpty()) {
			String errorMessage = String.format("Product" + productID + " already exist");
			throw new ChaincodeException(errorMessage);

		}

		Product product = new Product(productID, name, producer, "", "", "");
		productState = genson.serialize(product);
		stub.putStringState(productID, productState);
		return product;
	}

	// Transaction method to record the movement of a product in the supply chain
	@Transaction
	public Product recordProductMovement(final Context ctx, String productID, String type, String newStage) {

		ChaincodeStub stub = ctx.getStub();

		String productState = stub.getStringState(productID);
		if (productState == null || productState.isEmpty()) {
			String errorMessage = String.format("Product" + productID + " not found");
			throw new ChaincodeException(errorMessage);

		}

		// Product product = Product.fromJSONString(productJSON);

		Product product = genson.deserialize(productState, Product.class);
		String newProductState="";
		if ("distributor".equals(type)) {
		    Product newProduct = new Product(product.getID(), product.getName(), product.getProducer(), newStage, "", "");
		    newProductState = genson.serialize(newProduct);
		} else if ("retailer".equals(type)) {
		    Product newProduct = new Product(product.getID(), product.getName(), product.getProducer(), product.getDistributor(), newStage, "");
		    newProductState = genson.serialize(newProduct);
		} else if ("consumer".equals(type)) {
		    Product newProduct = new Product(product.getID(), product.getName(), product.getProducer(), product.getDistributor(), product.getRetailer(), newStage);
		    newProductState = genson.serialize(newProduct);
		}

		stub.putStringState(productID, newProductState);

		return product;
	}

	// Transaction method to query information about a product based on its ID
	@Transaction
	public Product queryProductByID(final Context ctx, String productID) {
		ChaincodeStub stub = ctx.getStub();
		String productState = stub.getStringState(productID);
		if (productState == null || productState.isEmpty()) {
			String errorMessage = String.format("Product" + productID + " not found");
			throw new ChaincodeException(errorMessage);
		}

		Product product = genson.deserialize(productState, Product.class);

		return product;
	}

}


