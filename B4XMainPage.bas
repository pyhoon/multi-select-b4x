B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region
'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private DB As MiniORM
	Private DBConnector As DatabaseConnector
	Private lblTitle As B4XView
	Private lblBack As B4XView
	Private clvRecord As CustomListView
	Private btnEdit As B4XView
	Private btnDelete As B4XView
	Private btnNew As B4XView
	Private lblName As B4XView
	Private lblCategory As B4XView
	Private lblCode As B4XView
	Private lblPrice As B4XView
	Private lblStatus As B4XView
	Private chkSelect As B4XView
	Private SelectedItems As List
	Private PrefDialog1 As PreferencesDialog
	Private PrefDialog2 As PreferencesDialog
	Private PrefDialog3 As PreferencesDialog
	Private PrefDialog4 As PreferencesDialog
	Private Viewing As String
	Private CategoryId As Int
	Private Category() As Category
	Private Product() As Product
	Private Const COLOR_RED As Int = -65536
	Private Const COLOR_BLUE As Int = -16776961
	Private Const COLOR_MAGENTA As Int = -65281
	Private Const COLOR_ADD As Int = -13447886
	Private Const COLOR_EDIT As Int = -12490271
	Private Const COLOR_DELETE As Int = -2354116
	Private Const COLOR_OVERLAY As Int = -2147481048
	Private Const COLOR_TRANSPARENT As Int = 0
	Type Category (Id As Int, Name As String, Selected As Boolean)
	Type Product (Id As Int, Name As String, Selected As Boolean, Code As String, Price As String, Category_Id As Int, Category_Name As String)
	Private btnRemove As Button
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MiniORM")
	SelectedItems.Initialize
	CreateDialog1
	CreateDialog3
	CreateDialog4
	ConfigureDatabase
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If xui.IsB4A Then
		'back key in Android
		If PrefDialog1.BackKeyPressed Then Return False
		If PrefDialog2.BackKeyPressed Then Return False
		If PrefDialog3.BackKeyPressed Then Return False
		If PrefDialog4.BackKeyPressed Then Return False
	End If
	If Viewing = "Product" Then
		SelectedItems.Clear
		GetCategories
		Return False
	End If
	DBClose
	Return True
End Sub

Private Sub B4XPage_Appear
	'GetCategories
End Sub

Private Sub B4XPage_Resize(Width As Int, Height As Int)
	If PrefDialog1.IsInitialized And PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Resize(Width, Height)
	If PrefDialog2.IsInitialized And PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Resize(Width, Height)
	If PrefDialog3.IsInitialized And PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Resize(Width, Height)
	If PrefDialog4.IsInitialized And PrefDialog4.Dialog.Visible Then PrefDialog4.Dialog.Resize(Width, Height)
End Sub

'Don't miss the code in the Main module + manifest editor.
Private Sub IME_HeightChanged (NewHeight As Int, OldHeight As Int)
	PrefDialog1.KeyboardHeightChanged(NewHeight)
	If PrefDialog2.IsInitialized Then PrefDialog2.KeyboardHeightChanged(NewHeight)
	PrefDialog3.KeyboardHeightChanged(NewHeight)
	PrefDialog4.KeyboardHeightChanged(NewHeight)
End Sub

#If B4J
Private Sub lblBack_MouseClicked (EventData As MouseEvent)
	GetCategories
End Sub
#Else
Private Sub lblBack_Click
	SelectedItems.Clear
	GetCategories
End Sub
#End If

Private Sub clvRecord_ItemClick (Index As Int, Value As Object)
	If Viewing = "Category" Then
		CategoryId = Value
		SelectedItems.Clear
		CreateDialog2
		GetProducts
	End If
End Sub

Private Sub SelectedCount As Int
	Dim TotalChecked As Int
	For i = 0 To clvRecord.Size - 1
		Dim p As B4XView = clvRecord.GetPanel(i)
		If Viewing = "Product" Then
			Dim chk As CheckBox = p.GetView(0).GetView(6)
		Else
			Dim chk As CheckBox = p.GetView(0).GetView(3)
		End If
		If chk.Checked Then
			TotalChecked = TotalChecked + 1
		End If
	Next
	Return TotalChecked
End Sub

Private Sub btnNew_Click
	If Viewing = "Product" Then
		Dim ProductMap As Map = CreateMap("Product Code": "", "Category": GetCategoryName(CategoryId), "Product Name": "", "Product Price": "", "id": 0)
		ShowDialog2("Add", ProductMap)
	Else
		Dim CategoryMap As Map = CreateMap("Category Name": "", "id": 0)
		ShowDialog1("Add", CategoryMap)
	End If
End Sub

' Bulk Delete
Private Sub btnRemove_Click
	If SelectedCount = 0 Then Return
	ShowDialog4
End Sub

Private Sub btnEdit_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim ProductId As Int = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		#If B4i
		Dim v2 As B4XView = pnl.GetView(1).GetView(0) ' using panel
		#Else
		Dim v2 As B4XView = pnl.GetView(1)
		#End If
		Dim v3 As B4XView = pnl.GetView(2)
		Dim v4 As B4XView = pnl.GetView(3)
		Dim ProductMap As Map = CreateMap("Product Code": v1.Text, "Category": v2.Text, "Product Name": v3.Text, "Product Price": v4.Text.Replace(",", ""), "id": ProductId)
		ShowDialog2("Edit", ProductMap)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		Dim CategoryMap As Map = CreateMap("Category Name": v1.Text, "id": CategoryId)
		ShowDialog1("Edit", CategoryMap)
	End If
End Sub

Private Sub btnDelete_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim M1 As Map
	M1.Initialize
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		M1.Put("id", Product(Index).Id)
		M1.Put("Name", Product(Index).Name)
	Else
		CategoryId = clvRecord.GetValue(Index)
		M1.Put("id", Category(Index).Id)
		M1.Put("Name", Category(Index).Name)
	End If	
	ShowDialog3(M1)', Index)
End Sub

Private Sub chkSelect_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim p As B4XView = clvRecord.GetPanel(Index)
	If Viewing = "Product" Then
		Dim chk As CheckBox = p.GetView(0).GetView(6)
		Product(Index).Selected = chk.Checked
		Dim Product_Id As Int = Product(Index).Id
		If chk.Checked Then
			If SelectedItems.IndexOf(Product_Id) < 0 Then SelectedItems.Add(Product_Id)
		Else
			If SelectedItems.IndexOf(Product_Id) > -1 Then SelectedItems.RemoveAt(SelectedItems.IndexOf(Product_Id))
		End If
	Else
		Dim chk As CheckBox = p.GetView(0).GetView(3)
		Category(Index).Selected = chk.Checked
		Dim Category_Id As Int = Category(Index).Id
		If chk.Checked Then
			If SelectedItems.IndexOf(Category_Id) < 0 Then SelectedItems.Add(Category_Id)
		Else
			If SelectedItems.IndexOf(Category_Id) > -1 Then SelectedItems.RemoveAt(SelectedItems.IndexOf(Category_Id))
		End If
	End If
	Log(SelectedItems)
End Sub

Private Sub DBEngine As String
	Return DBConnector.DBEngine
End Sub

Private Sub DBOpen As SQL
	Return DBConnector.DBOpen
End Sub

Private Sub DBClose
	DBConnector.DBClose
End Sub

Public Sub ConfigureDatabase
	Dim con As Conn
	con.Initialize
	con.DBType = "SQLite"
	con.DBFile = "MiniORM.db"
	
	#If B4J
	con.DBDir = File.DirApp
	#Else
	con.DBDir = xui.DefaultFolder 
	#End If

	#If B4J
	'con.DBType = "MySQL"
	'con.DBName = "miniorm"
	'con.DbHost = "localhost"
	'con.User = "root"
	'con.Password = "password"
	'con.DriverClass = "com.mysql.cj.jdbc.Driver"
	'con.JdbcUrl = "jdbc:mysql://{DbHost}:{DbPort}/{DbName}?characterEncoding=utf8&useSSL=False"
	#End If

	Try
		DBConnector.Initialize(con)
		Dim DBFound As Boolean = DBConnector.DBExist
		If DBFound Then
			LogColor($"${con.DBType} database found!"$, COLOR_BLUE)
			DB.Initialize(DBOpen, DBEngine)
			'DB.ShowExtraLogs = True
			GetCategories
		Else
			LogColor($"${con.DBType} database not found!"$, COLOR_RED)
			CreateDatabase
		End If
	Catch
		Log(LastException.Message)
		LogColor("Error checking database!", COLOR_RED)
		Log("Application is terminated.")
		#If B4J
		ExitApplication
		#End If
	End Try
End Sub

Private Sub CreateDatabase
	LogColor("Creating database...", COLOR_MAGENTA)
	Wait For (DBConnector.DBCreate) Complete (Success As Boolean)
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If
	
	Dim MDB As MiniORM
	MDB.Initialize(DBOpen, DBEngine)
	MDB.UseTimestamps = True
	MDB.AddAfterCreate = True
	MDB.AddAfterInsert = True
	
	MDB.Table = "tbl_categories"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_name")))
	MDB.Create

	MDB.Columns = Array("category_name")
	MDB.Insert2(Array As String("Hardwares"))
	MDB.Insert2(Array As String("Toys"))

	MDB.Table = "tbl_products"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_id", "Type": MDB.INTEGER)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_code", "Size": 12)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_name")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_price", "Type": MDB.DECIMAL, "Size": "10,2", "Default": 0.0)))
	MDB.Foreign("category_id", "id", "tbl_categories", "", "")
	MDB.Create
	
	MDB.Columns = Array("category_id", "product_code", "product_name", "product_price")
	MDB.Insert2(Array As String(2, "T001", "Teddy Bear", 99.9))
	MDB.Insert2(Array As String(1, "H001", "Hammer", 15.75))
	MDB.Insert2(Array As String(2, "T002", "Optimus Prime", 1000))
	
	Wait For (MDB.ExecuteBatch) Complete (Success As Boolean)
	If Success Then
		LogColor("Database is created successfully!", COLOR_BLUE)
	Else
		LogColor("Database creation failed!", COLOR_RED)
		Log(LastException)
	End If
	MDB.Close
	DB.Initialize(DBOpen, DBEngine)
	GetCategories
End Sub

Private Sub GetCategories
	'Try
		clvRecord.Clear
		'SelectedItems.Clear
		Dim i As Int
		DB.Table = "tbl_categories"
		DB.Query
		Dim Items As List = DB.Results
		Dim Category(Items.Size) As Category
		For Each Item As Map In Items
			Category(i).Id = Item.Get("id")
			Category(i).Name = Item.Get("category_name")
			Category(i).Selected = SelectedItems.IndexOf(Category(i).Id) > -1
			clvRecord.Add(CreateCategoryItems(Category(i), clvRecord.AsView.Width), Category(i).Id)
			i = i + 1
		Next
		lblTitle.Text = "Category"
		lblBack.Visible = False
		Viewing = "Category"
	'Catch
	'	xui.MsgboxAsync(LastException.Message, "Error")
	'End Try
End Sub

Private Sub GetProducts
	'Try
		clvRecord.Clear
		Dim i As Int
		DB.Table = "tbl_products p"
		DB.Select = Array("p.*", "c.category_name")
		DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
		DB.WhereValue(Array("c.id = ?"), Array As String(CategoryId))
		DB.Query
		Dim Items As List = DB.Results
		Dim Product(Items.Size) As Product
		For Each Item As Map In Items
			Product(i).Id = Item.Get("id")
			Product(i).Name = Item.Get("product_name")
			Product(i).Code = Item.Get("product_code")
			Product(i).Price = NumberFormat2(Item.Get("product_price"), 1, 2, 2, True)
			Product(i).Category_Id = Item.Get("category_id")
			Product(i).Category_Name = Item.Get("category_name")
			Product(i).Selected = SelectedItems.IndexOf(Product(i).Id) > -1
			clvRecord.Add(CreateProductItems(Product(i), clvRecord.AsView.Width), Product(i).Id)
			i = i + 1
		Next
	
		lblTitle.Text = GetCategoryName(CategoryId)
		lblBack.Visible = True
		Viewing = "Product"
	'Catch
	'	xui.MsgboxAsync(LastException.Message, "Error")
	'End Try
End Sub

Private Sub GetCategoryId (Name As String) As Int
	Dim i As Int
	For i = 0 To Category.Length - 1
		If Category(i).Name = Name Then
			Return Category(i).Id
		End If
	Next
	Return 0
End Sub

Private Sub GetCategoryName (Id As Int) As String
	Dim i As Int
	For i = 0 To Category.Length - 1
		If Category(i).Id = Id Then
			Return Category(i).Name
		End If
	Next
	Return ""
End Sub

Private Sub CreateCategoryItems (Item As Category, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 90dip)
	p.LoadLayout("CategoryItem")
	lblName.Text = Item.Name
	chkSelect.Checked = Item.Selected
	Return p
End Sub

Private Sub CreateProductItems (Item As Product, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	p.LoadLayout("ProductItem")
	lblCode.Text = Item.Code
	lblCategory.Text = Item.Category_Name
	lblName.Text = Item.Name
	lblPrice.Text = Item.Price
	chkSelect.Checked = Item.Selected
	Return p
End Sub

Private Sub CreateDialog1
	PrefDialog1.Initialize(Root, "Category", 300dip, 70dip)
	PrefDialog1.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog1.Dialog.TitleBarHeight = 50dip
	PrefDialog1.LoadFromJson(File.ReadString(File.DirAssets, "template_category.json"))
	PrefDialog1.SetEventsListener(Me, "PrefDialog1") '<-- must add to handle events
End Sub

Private Sub CreateDialog2
	Dim categories As List
	categories.Initialize
	For i = 0 To Category.Length - 1
		categories.Add(Category(i).Name)
	Next
	PrefDialog2.Initialize(Root, "Product", 300dip, 250dip)
	PrefDialog2.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog2.Dialog.TitleBarHeight = 50dip
	PrefDialog2.LoadFromJson(File.ReadString(File.DirAssets, "template_product.json"))
	PrefDialog2.SetOptions("Category", categories)
	PrefDialog2.SetEventsListener(Me, "PrefDialog2") '<-- must add to handle events
End Sub

Private Sub CreateDialog3
	PrefDialog3.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog3.Theme = PrefDialog3.THEME_LIGHT
	PrefDialog3.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog3.Dialog.TitleBarHeight = 50dip
	PrefDialog3.Dialog.TitleBarColor = COLOR_DELETE
	PrefDialog3.AddSeparator("default")
	PrefDialog3.SetEventsListener(Me, "PrefDialog3") '<-- must add to handle events
End Sub

Private Sub CreateDialog4
	PrefDialog4.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog4.Theme = PrefDialog4.THEME_LIGHT
	PrefDialog4.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog4.Dialog.TitleBarHeight = 50dip
	PrefDialog4.Dialog.TitleBarColor = COLOR_DELETE
	PrefDialog4.AddSeparator("default")
	PrefDialog4.SetEventsListener(Me, "PrefDialog4") '<-- must add to handle events
End Sub

Private Sub PrefDialog1_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog1)
End Sub

Private Sub PrefDialog2_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog2)
End Sub

Private Sub PrefDialog3_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog3)
End Sub

Private Sub PrefDialog4_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog4)
End Sub

Private Sub AdjustDialogText (Pref As PreferencesDialog)
	Try
		Dim btnCancel As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Cancel)
		btnCancel.Width = btnCancel.Width + 20dip
		btnCancel.Left = btnCancel.Left - 20dip
		btnCancel.TextColor = COLOR_RED
		Dim btnOk As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Positive)
		If btnOk.IsInitialized Then
			btnOk.Width = btnOk.Width + 20dip
			btnOk.Left = btnCancel.Left - btnOk.Width
		End If
	Catch
		Log(LastException)
	End Try
End Sub

Private Sub ShowDialog1 (Action As String, Item As Map)
	PrefDialog1.Dialog.TitleBarColor = IIf(Action = "Add", COLOR_ADD, COLOR_EDIT)
	PrefDialog1.Title = Action & " Category"
	Dim sf As Object = PrefDialog1.ShowDialog(Item, "OK", "CANCEL")
	#If B4A or B4i
	PrefDialog1.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	Sleep(0)
	PrefDialog1.CustomListView1.sv.Height = PrefDialog1.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim Category_Name As String = Item.Get("Category Name")
		If Action = "Add" Then
			DB.Table = "tbl_categories"
			DB.WhereValue(Array("category_name = ?"), Array As String(Category_Name))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Category already exist", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_name")
			DB.Save2(Array As String(Category_Name))
			xui.MsgboxAsync("New category created!", $"ID: ${DB.First.Get("id")}"$)
		Else
			DB.Table = "tbl_categories"
			DB.Columns = Array("category_name")
			DB.Parameters = Array As String(Category_Name)
			DB.Id = Item.Get("id")
			DB.Save
			xui.MsgboxAsync("Category updated!", "Edit")
		End If
		GetCategories
	Else
		Return
	End If
End Sub

Private Sub ShowDialog2 (Action As String, Item As Map)
	PrefDialog2.Dialog.TitleBarColor = IIf(Action = "Add", COLOR_ADD, COLOR_EDIT)
	PrefDialog2.Title = Action & " Product"
	Dim sf As Object = PrefDialog2.ShowDialog(Item, "OK", "CANCEL")
	Sleep(0)
	PrefDialog2.CustomListView1.sv.Height = PrefDialog2.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim Category_Name As String = Item.Get("Category")
		Dim Product_Name As String = Item.Get("Product Name")
		Dim Product_Code As String = Item.Get("Product Code")
		Dim Product_Price As String = Item.Get("Product Price")
		Dim Product_Id As Int = Item.Get("id")
		Dim Category_Id As Int = GetCategoryId(Category_Name)
		If Action = "Add" Then
			DB.Table = "tbl_products"
			DB.setWhereValue(Array("product_code = ?"), Array As String(Product_Code))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Product_Price) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			DB.Save2(Array As String(CategoryId, Product_Code, Product_Name, Product_Price))
			CategoryId = Category_Id
			xui.MsgboxAsync("New product created!", $"ID: ${DB.First.Get("id")}"$)
		Else
			DB.Table = "tbl_products"
			DB.setWhereValue(Array("product_code = ?", "id <> ?"), Array As String(Product_Code, Product_Id))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Item.Get("Product Price")) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			DB.Parameters = Array As String(Category_Id, Product_Code, Product_Name, Product_Price)
			DB.Id = Item.Get("id")
			DB.Save
			xui.MsgboxAsync("Product updated!", "Edit")
			CategoryId = Category_Id
		End If
		GetProducts
	Else
		Return
	End If
End Sub

Private Sub ShowDialog3 (Item As Map)', Index As Int)
	Dim Id As Int = Item.Get("id")
	Dim Name As String = Item.Get("Name")
	PrefDialog3.Title = "Delete " & Viewing
	Dim sf As Object = PrefDialog3.ShowDialog(Item, "OK", "CANCEL")
	#If B4A or B4i
	PrefDialog3.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	Sleep(0)
	PrefDialog3.CustomListView1.sv.Height = PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	#If B4i
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Color = COLOR_TRANSPARENT
	PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Color = COLOR_TRANSPARENT
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = Name
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		DB.Table = IIf(Viewing = "Product", "tbl_products", "tbl_categories")
		DB.Find(Id)
		If DB.Found Then
			DB.Reset
			DB.Id = Id
			DB.Delete
			'SelectedItems.RemoveAt(Index)
			If SelectedItems.IndexOf(Id) > -1 Then SelectedItems.RemoveAt(SelectedItems.IndexOf(Id))
			xui.MsgboxAsync(Viewing & " deleted successfully", "Delete")
		Else
			xui.MsgboxAsync(Viewing & " not found", "Error")
		End If
	Else
		Return
	End If
	If Viewing = "Product" Then GetProducts Else GetCategories
End Sub

Private Sub ShowDialog4
	PrefDialog4.Title = "Bulk Delete " & Viewing
	Dim sf As Object = PrefDialog4.ShowDialog(Null, "OK", "CANCEL")
	#If B4A or B4i
	PrefDialog4.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	Sleep(0)
	PrefDialog4.CustomListView1.sv.Height = PrefDialog4.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	#If B4i
	PrefDialog4.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog4.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	PrefDialog4.CustomListView1.GetPanel(0).GetView(0).Color = COLOR_TRANSPARENT
	PrefDialog4.CustomListView1.sv.ScrollViewInnerPanel.Color = COLOR_TRANSPARENT
	Dim count As Int = SelectedCount
	PrefDialog4.CustomListView1.GetPanel(0).GetView(0).Text = count & " items?"
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		DB.Table = IIf(Viewing = "Product", "tbl_products", "tbl_categories")
		' Convert list to array
		Dim i As Int
		Dim Ids(count) As Int
		For index = 0 To clvRecord.Size - 1
			Dim p As B4XView = clvRecord.GetPanel(index)
			If Viewing = "Product" Then
				Dim chk As CheckBox = p.GetView(0).GetView(6)
				If chk.Checked Then				
					Ids(i) = Product(index).Id
					Log(Ids(i))
					i = i + 1
				End If
			Else
				Dim chk As CheckBox = p.GetView(0).GetView(3)
				If chk.Checked Then
					Ids(i) = Category(index).Id
					Log(Ids(i))
					i = i + 1
				End If
			End If
		Next
		DB.Destroy(Ids)
		'SelectedItems.Clear
		xui.MsgboxAsync(count & " items deleted successfully", "Delete")
	Else
		Return
	End If
	If Viewing = "Product" Then GetProducts Else GetCategories
End Sub