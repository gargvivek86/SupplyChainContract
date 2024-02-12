package SupplyChainContract;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

@DataType()
public final class Product {

	@Property()
	private String ID;
	@Property()
	private String name;
	@Property()
	private String producer;
	@Property()
	private String distributor;
	@Property()
	private String retailer;
	@Property()
	private String consumer;

	// Getter methods for each attribute
	public String getID() {
		return ID;
	}

	public String getName() {
		return name;
	}

	public String getProducer() {
		return producer;
	}

	public String getDistributor() {
		return distributor;
	}

	public String getRetailer() {
		return retailer;
	}

	public String getConsumer() {
		return consumer;
	}

	public Product(@JsonProperty("ID") final String ID, @JsonProperty("name") final String name,
			@JsonProperty("producer") final String producer, @JsonProperty("distributor") final String distributor,
			@JsonProperty("retailer") final String retailer, @JsonProperty("consumer") final String consumer) {
		this.ID = ID;
		this.name = name;
		this.producer = producer;
		this.distributor = distributor;
		this.retailer = retailer;
		this.consumer = consumer;
	}

}

