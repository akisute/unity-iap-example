using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;


public class StoreKit : MonoBehaviour
{
	//////////////////////////////////////////////////////////////////////////
	// Init/dealloc
	//////////////////////////////////////////////////////////////////////////
	
	private static StoreKit instance = null;
	
	public static StoreKit GetInstance()
	{
		if (instance == null) {
			GameObject obj = new GameObject("StoreKit");
			instance = obj.AddComponent<StoreKit>();
		}
		return instance;
	}
	
	void Awake()
	{
		DontDestroyOnLoad(gameObject);
		Install();
	}
	
	//////////////////////////////////////////////////////////////////////////
	// Properties
	//////////////////////////////////////////////////////////////////////////
	
	// parameter = productIdentifier
	public Action<string> handlerBuyFinished { get; set; }
	// parameter = productIdentifier
	public Action<string> handlerBuyFailed { get; set; }
	// parameter = a dictionary <productIdentifier, priceString>
	public Action<Dictionary<string, string>> handlerRequestProductPriceFinished { get; set; }
	
	public bool isAvailable
	{
		get {
			#if UNITY_IPHONE && !UNITY_EDITOR
				return _StoreKitIsAvailable();
			#else
				return true;
			#endif
		}
	}

	public bool isProcessing
	{
		get {
			#if UNITY_IPHONE && !UNITY_EDITOR
				return _StoreKitIsProcessing();
			#else
				return false;
			#endif
		}
	}
	
	//////////////////////////////////////////////////////////////////////////
	// Querying purchased receipts
	//////////////////////////////////////////////////////////////////////////
	
	private static string GetReceiptsPrefsKey(string productIdentifier)
	{
		return string.Format("StoreKitReceipts-{0}", productIdentifier);
	}
	
	public bool HasProductReceipts(string productIdentifier)
	{
		string receiptBase64CommaDelimitedString = PlayerPrefs.GetString(GetReceiptsPrefsKey(productIdentifier), null);
		return !string.IsNullOrEmpty(receiptBase64CommaDelimitedString);
	}
	
	public string[] GetProductReceipts(string productIdentifier)
	{
		string receiptBase64CommaDelimitedString = PlayerPrefs.GetString(GetReceiptsPrefsKey(productIdentifier), null);
		if (string.IsNullOrEmpty(receiptBase64CommaDelimitedString)) {
			return new string[0];
		}
		
		string[] receiptBase64Strings = receiptBase64CommaDelimitedString.Split(new char[]{','});
		return receiptBase64Strings;
	}
	
	public string GetFirstProductReceipt(string productIdentifier)
	{
		string[] receiptBase64Strings = GetProductReceipts(productIdentifier);
		if (receiptBase64Strings.Length > 0) {
			return receiptBase64Strings[0];
		} else {
			return null;
		}
	}
	
	public bool ConsumeFirstProductReceipt(string productIdentifier)
	{
		string[] receiptBase64Strings = GetProductReceipts(productIdentifier);
		if (receiptBase64Strings.Length > 1) {
			string[] consumedReceiptBase64Strings = new string[receiptBase64Strings.Length-1];
			System.Array.Copy(receiptBase64Strings, 1, consumedReceiptBase64Strings, 0, receiptBase64Strings.Length-1);
			PlayerPrefs.SetString(GetReceiptsPrefsKey(productIdentifier), string.Join(",", consumedReceiptBase64Strings));
			PlayerPrefs.Save();
			return true;
		} else if (receiptBase64Strings.Length == 1) {
			PlayerPrefs.SetString(GetReceiptsPrefsKey(productIdentifier), "");
			PlayerPrefs.Save();
			return true;
		} else {
			return false;
		}
	}
	
	//////////////////////////////////////////////////////////////////////////
	// Public API
	//////////////////////////////////////////////////////////////////////////
	
	public void Install()
	{
		#if UNITY_IPHONE && !UNITY_EDITOR
			_StoreKitInstall();
		#endif
	}
	
	public void Buy(string productIdentifier)
	{
		#if UNITY_IPHONE && !UNITY_EDITOR
			_StoreKitBuy(productIdentifier);
		#else
			const string DummyReceiptBase64String = "thisisdummyreceiptbase64string";
			string[] receiptBase64Strings = GetProductReceipts(productIdentifier);
			ArrayList buffer = new ArrayList(receiptBase64Strings);
			buffer.Add(DummyReceiptBase64String);
			receiptBase64Strings = (string[])buffer.ToArray(typeof(string));
			PlayerPrefs.SetString(GetReceiptsPrefsKey(productIdentifier), string.Join(",", receiptBase64Strings));
			PlayerPrefs.Save();
			BuyFinished(productIdentifier);
		#endif
	}
	
	public void RequestProductPriceString(string[] productIdentifiers)
	{
		#if UNITY_IPHONE && !UNITY_EDITOR
			_StoreKitRequestProductPriceString(productIdentifiers);
		#else
			StringBuilder buffer = new StringBuilder();
			foreach (string productIdentifier in productIdentifiers) {
				if (buffer.Length > 0) {
					buffer.Append("|");
				}
				buffer.AppendFormat("{0}:{1}", productIdentifier, "85");
			}
			RequestProductPriceFinished(buffer.ToString());
		#endif
	}
	
	public void RequestProductPriceLocalizedString(string[] productIdentifiers)
	{
		#if UNITY_IPHONE && !UNITY_EDITOR
			_StoreKitRequestProductLocalizedPriceString(productIdentifiers);
		#else
			StringBuilder buffer = new StringBuilder();
			foreach (string productIdentifier in productIdentifiers) {
				if (buffer.Length > 0) {
					buffer.Append("|");
				}
				buffer.AppendFormat("{0}:{1}", productIdentifier, "85�~");
			}
			RequestProductPriceFinished(buffer.ToString());
		#endif
	}
	
	#if UNITY_IPHONE
	
	[DllImport ("__Internal")]
	private static extern void _StoreKitInstall();
	[DllImport ("__Internal")]
	private static extern bool _StoreKitIsAvailable();
	[DllImport ("__Internal")]
	private static extern void _StoreKitBuy(string productName);
	[DllImport ("__Internal")]
	private static extern bool _StoreKitIsProcessing();
	[DllImport ("__Internal")]
	private static extern void _StoreKitRequestProductPriceString(string[] productIdentifiers);
	[DllImport ("__Internal")]
	private static extern void _StoreKitRequestProductLocalizedPriceString(string[] productIdentifiers);
	
	#endif
	
	//////////////////////////////////////////////////////////////////////////
	// Callbacks from iOS plugin
	//////////////////////////////////////////////////////////////////////////
	
	private void BuyFinished(string productIdentifier)
	{
		if (handlerBuyFinished != null) {
			handlerBuyFinished(productIdentifier);
		}
	}
	
	private void BuyFailed(string productIdentifier)
	{
		if (handlerBuyFailed != null) {
			handlerBuyFailed(productIdentifier);
		}
	}
	
	private void RequestProductPriceFinished(string productPriceInfoString)
	{
		// The format of the productPriceInfoString should be like this
		//
		//     productIdentifier:priceString|productIdentifier:priceString|productIdentifier:priceString
		//
		if (handlerRequestProductPriceFinished != null) {
			Dictionary<string, string> priceInfo = new Dictionary<string, string>();
			if (!string.IsNullOrEmpty(productPriceInfoString)) {
				string[] entryStrings = productPriceInfoString.Split(new char[]{'|'});
				foreach(string entryString in entryStrings) {
					string[] keyAndValue = entryString.Split(new char[]{':'});
					if (keyAndValue.Length == 2) {
						priceInfo.Add(keyAndValue[0], keyAndValue[1]);
					}
				}
			}
			handlerRequestProductPriceFinished(priceInfo);
		}
	}
}
