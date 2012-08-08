import System.Collections.Generic;

var skin : GUISkin;
var fontLoRes : Font;
var fontHiRes : Font;
var productInfo : Dictionary.<String, String>;

function Start() {
	skin = Instantiate(skin) as GUISkin;
	skin.font = Screen.width < 500 ? fontLoRes : fontHiRes;
	
	var store : StoreKit = StoreKit.GetInstance();
	store.Install();
	store.handlerBuyFinished = function(productIdentifier : String) {
		Debug.Log("Buy Finished: " + productIdentifier);
		var coin = SecureData.GetInt("Coin");
		if (store.ConsumeFirstProductReceipt("net.appbankgames.dungeonsandgolf.ticket.tier1")) {
			SecureData.SetInt("Coin", coin + 1000);
			SecureData.Flush();
		} else if (store.ConsumeFirstProductReceipt("net.appbankgames.dungeonsandgolf.ticket.tier2")) {
			SecureData.SetInt("Coin", coin + 2500);
			SecureData.Flush();
		} else if (store.ConsumeFirstProductReceipt("net.appbankgames.dungeonsandgolf.ticket.tier3")) {
			SecureData.SetInt("Coin", coin + 4000);
			SecureData.Flush();
		} else if (store.ConsumeFirstProductReceipt("net.appbankgames.dungeonsandgolf.ticket.tier4")) {
			SecureData.SetBool("UnlockLevelX", true);
			SecureData.Flush();
		} else if (store.ConsumeFirstProductReceipt("net.appbankgames.dungeonsandgolf.ticket.tier5")) {
			SecureData.SetBool("UnlockLevelY", true);
			SecureData.Flush();
		}
	};
	store.handlerBuyFailed = function(productIdentifier : String) {
		Debug.Log("Buy Failed: " + productIdentifier);
	};
	store.handlerRequestProductPriceFinished = function(productInfo : Dictionary.<String, String>) {
		Debug.Log("Request product price Finished");
		this.productInfo = productInfo;
	};
	store.RequestProductPriceString([
		"net.appbankgames.dungeonsandgolf.ticket.tier1",
		"net.appbankgames.dungeonsandgolf.ticket.tier2",
		"net.appbankgames.dungeonsandgolf.ticket.tier3",
		"net.appbankgames.dungeonsandgolf.ticket.tier4",
		"net.appbankgames.dungeonsandgolf.ticket.tier5"
	]);
}

function OnGUI() {
	if (!StoreKit.GetInstance().isAvailable) return;
	
	var deactivated = StoreKit.GetInstance().isProcessing;
	
	GUI.skin = skin;
	GUI.color = Color(1, 1, 1, deactivated ? 0.2 : 1.0);
	
	var coin = SecureData.GetInt("Coin");
	var levelX = SecureData.GetBool("UnlockLevelX");
	var levelY = SecureData.GetBool("UnlockLevelY");
	
	GUILayout.BeginArea(Rect(10, 0, Screen.width - 20, Screen.height));
	GUILayout.FlexibleSpace();

	GUILayout.Label("Coins: " + coin.ToString());
	GUILayout.Label("Unlocked levels: " + (levelX ? "X" : "") + (levelY ? "Y" : ""));

	if (coin > 1234) {
		GUILayout.FlexibleSpace();
		
		if (GUILayout.Button("Use 1,234 coins") && !deactivated) {
			SecureData.SetInt("Coin", coin - 1234);
			SecureData.Flush();
		}
	}

	GUILayout.FlexibleSpace();

	GUILayout.Label("Buy coins:");

	var titleCoin1000 : String = null;
	if (productInfo != null && productInfo.ContainsKey("net.appbankgames.dungeonsandgolf.ticket.tier1")) {
		titleCoin1000 = String.Format("1,000 coin pack - {0}", productInfo["net.appbankgames.dungeonsandgolf.ticket.tier1"]);
	} else {
		titleCoin1000 = "1,000 coin pack";
	}
	if (GUILayout.Button(titleCoin1000) && !deactivated) {
		StoreKit.GetInstance().Buy("net.appbankgames.dungeonsandgolf.ticket.tier1");
	}

	var titleCoin2500 : String = null;
	if (productInfo != null && productInfo.ContainsKey("net.appbankgames.dungeonsandgolf.ticket.tier2")) {
		titleCoin2500 = String.Format("2,500 coin pack - {0}", productInfo["net.appbankgames.dungeonsandgolf.ticket.tier2"]);
	} else {
		titleCoin2500 = "2,500 coin pack";
	}
	if (GUILayout.Button(titleCoin2500) && !deactivated) {
		StoreKit.GetInstance().Buy("net.appbankgames.dungeonsandgolf.ticket.tier2");
	}
	
	var titleCoin4000 : String = null;
	if (productInfo != null && productInfo.ContainsKey("net.appbankgames.dungeonsandgolf.ticket.tier3")) {
		titleCoin4000 = String.Format("4,000 coin pack - {0}", productInfo["net.appbankgames.dungeonsandgolf.ticket.tier3"]);
	} else {
		titleCoin4000 = "4,000 coin pack";
	}
	if (GUILayout.Button(titleCoin4000) && !deactivated) {
		StoreKit.GetInstance().Buy("net.appbankgames.dungeonsandgolf.ticket.tier3");
	}
	
	if (!levelX || !levelY) {
		GUILayout.FlexibleSpace();
	
		GUILayout.Label("Buy additional levels:");
	
		if (!levelX && GUILayout.Button("Unlock level X") && !deactivated) {
			StoreKit.GetInstance().Buy("net.appbankgames.dungeonsandgolf.ticket.tier1");
		}
	
		if (!levelY && GUILayout.Button("Unlock level Y") && !deactivated) {
			StoreKit.GetInstance().Buy("net.appbankgames.dungeonsandgolf.ticket.tier1");
		}
	}

	GUILayout.FlexibleSpace();

	GUILayout.EndArea();
}
