﻿#pragma warning disable 1591
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.17929
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Harvester
{
	using System.Data.Linq;
	using System.Data.Linq.Mapping;
	using System.Data;
	using System.Collections.Generic;
	using System.Reflection;
	using System.Linq;
	using System.Linq.Expressions;
	using System.ComponentModel;
	using System;
	
	
	[global::System.Data.Linq.Mapping.DatabaseAttribute(Name="RedmineReport")]
	public partial class DatabaseDataContext : System.Data.Linq.DataContext
	{
		
		private static System.Data.Linq.Mapping.MappingSource mappingSource = new AttributeMappingSource();
		
    #region Extensibility Method Definitions
    partial void OnCreated();
    partial void InsertRepository(Repository instance);
    partial void UpdateRepository(Repository instance);
    partial void DeleteRepository(Repository instance);
    partial void InsertCustomerRepository(CustomerRepository instance);
    partial void UpdateCustomerRepository(CustomerRepository instance);
    partial void DeleteCustomerRepository(CustomerRepository instance);
    partial void InsertCustomer(Customer instance);
    partial void UpdateCustomer(Customer instance);
    partial void DeleteCustomer(Customer instance);
    #endregion
		
		public DatabaseDataContext() : 
				base(global::Harvester.Properties.Settings.Default.RedmineConnectionString, mappingSource)
		{
			OnCreated();
		}
		
		public DatabaseDataContext(string connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DatabaseDataContext(System.Data.IDbConnection connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DatabaseDataContext(string connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DatabaseDataContext(System.Data.IDbConnection connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public System.Data.Linq.Table<Repository> Repositories
		{
			get
			{
				return this.GetTable<Repository>();
			}
		}
		
		public System.Data.Linq.Table<CustomerRepository> CustomerRepositories
		{
			get
			{
				return this.GetTable<CustomerRepository>();
			}
		}
		
		public System.Data.Linq.Table<Customer> Customers
		{
			get
			{
				return this.GetTable<Customer>();
			}
		}
		
		[global::System.Data.Linq.Mapping.FunctionAttribute(Name="dbo.AddBookmark")]
		public ISingleResult<AddBookmarkResult> AddBookmark([global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string branch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string feature, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetId, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialBookmark)
		{
			IExecuteResult result = this.ExecuteMethodCall(this, ((MethodInfo)(MethodInfo.GetCurrentMethod())), branch, feature, mercurialChangesetId, mercurialBookmark);
			return ((ISingleResult<AddBookmarkResult>)(result.ReturnValue));
		}
		
		[global::System.Data.Linq.Mapping.FunctionAttribute(Name="dbo.AddBranch")]
		public ISingleResult<AddBranchResult> AddBranch([global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string branch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string feature, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetId, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialBranch)
		{
			IExecuteResult result = this.ExecuteMethodCall(this, ((MethodInfo)(MethodInfo.GetCurrentMethod())), branch, feature, mercurialChangesetId, mercurialBranch);
			return ((ISingleResult<AddBranchResult>)(result.ReturnValue));
		}
		
		[global::System.Data.Linq.Mapping.FunctionAttribute(Name="dbo.AddChangeset")]
		public ISingleResult<AddChangesetResult> AddChangeset([global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string customerCode, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(200)")] string repositoryURL, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string branch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string feature, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetId, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(100)")] string user, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="DateTime")] System.Nullable<System.DateTime> createdDateTime, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(500)")] string summary, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(MAX)")] string files, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetBranch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string issueNumber)
		{
			IExecuteResult result = this.ExecuteMethodCall(this, ((MethodInfo)(MethodInfo.GetCurrentMethod())), customerCode, repositoryURL, branch, feature, mercurialChangesetId, user, createdDateTime, summary, files, mercurialChangesetBranch, issueNumber);
			return ((ISingleResult<AddChangesetResult>)(result.ReturnValue));
		}
		
		[global::System.Data.Linq.Mapping.FunctionAttribute(Name="dbo.AddRepositoryEntry")]
		public ISingleResult<AddRepositoryEntryResult> AddRepositoryEntry([global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string customerCode, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(200)")] string repositoryURL, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string branch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string feature, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetId, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(100)")] string user, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="DateTime")] System.Nullable<System.DateTime> createdDateTime, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(500)")] string summary, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(MAX)")] string files, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(MAX)")] string branches, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(MAX)")] string bookmarks, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetBranch, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string issueNumber)
		{
			IExecuteResult result = this.ExecuteMethodCall(this, ((MethodInfo)(MethodInfo.GetCurrentMethod())), customerCode, repositoryURL, branch, feature, mercurialChangesetId, user, createdDateTime, summary, files, branches, bookmarks, mercurialChangesetBranch, issueNumber);
			return ((ISingleResult<AddRepositoryEntryResult>)(result.ReturnValue));
		}
		
		[global::System.Data.Linq.Mapping.FunctionAttribute(Name="dbo.AddPortal")]
		public ISingleResult<AddPortalResult> AddPortal([global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string mercurialChangesetId, [global::System.Data.Linq.Mapping.ParameterAttribute(DbType="NVarChar(50)")] string portal)
		{
			IExecuteResult result = this.ExecuteMethodCall(this, ((MethodInfo)(MethodInfo.GetCurrentMethod())), mercurialChangesetId, portal);
			return ((ISingleResult<AddPortalResult>)(result.ReturnValue));
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="dbo.Repository")]
	public partial class Repository : INotifyPropertyChanging, INotifyPropertyChanged
	{
		
		private static PropertyChangingEventArgs emptyChangingEventArgs = new PropertyChangingEventArgs(String.Empty);
		
		private int _Id;
		
		private string _Branch;
		
		private string _Feature;
		
		private string _URL;
		
		private System.Nullable<bool> _HarvestFlag;
		
		private EntitySet<CustomerRepository> _CustomerRepositories;
		
    #region Extensibility Method Definitions
    partial void OnLoaded();
    partial void OnValidate(System.Data.Linq.ChangeAction action);
    partial void OnCreated();
    partial void OnIdChanging(int value);
    partial void OnIdChanged();
    partial void OnBranchChanging(string value);
    partial void OnBranchChanged();
    partial void OnFeatureChanging(string value);
    partial void OnFeatureChanged();
    partial void OnURLChanging(string value);
    partial void OnURLChanged();
    partial void OnHarvestFlagChanging(System.Nullable<bool> value);
    partial void OnHarvestFlagChanged();
    #endregion
		
		public Repository()
		{
			this._CustomerRepositories = new EntitySet<CustomerRepository>(new Action<CustomerRepository>(this.attach_CustomerRepositories), new Action<CustomerRepository>(this.detach_CustomerRepositories));
			OnCreated();
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Id", AutoSync=AutoSync.OnInsert, DbType="Int NOT NULL IDENTITY", IsPrimaryKey=true, IsDbGenerated=true)]
		public int Id
		{
			get
			{
				return this._Id;
			}
			set
			{
				if ((this._Id != value))
				{
					this.OnIdChanging(value);
					this.SendPropertyChanging();
					this._Id = value;
					this.SendPropertyChanged("Id");
					this.OnIdChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Branch", DbType="NVarChar(50) NOT NULL", CanBeNull=false)]
		public string Branch
		{
			get
			{
				return this._Branch;
			}
			set
			{
				if ((this._Branch != value))
				{
					this.OnBranchChanging(value);
					this.SendPropertyChanging();
					this._Branch = value;
					this.SendPropertyChanged("Branch");
					this.OnBranchChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Feature", DbType="NVarChar(50) NOT NULL", CanBeNull=false)]
		public string Feature
		{
			get
			{
				return this._Feature;
			}
			set
			{
				if ((this._Feature != value))
				{
					this.OnFeatureChanging(value);
					this.SendPropertyChanging();
					this._Feature = value;
					this.SendPropertyChanged("Feature");
					this.OnFeatureChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_URL", DbType="NVarChar(500) NOT NULL", CanBeNull=false)]
		public string URL
		{
			get
			{
				return this._URL;
			}
			set
			{
				if ((this._URL != value))
				{
					this.OnURLChanging(value);
					this.SendPropertyChanging();
					this._URL = value;
					this.SendPropertyChanged("URL");
					this.OnURLChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_HarvestFlag", DbType="Bit")]
		public System.Nullable<bool> HarvestFlag
		{
			get
			{
				return this._HarvestFlag;
			}
			set
			{
				if ((this._HarvestFlag != value))
				{
					this.OnHarvestFlagChanging(value);
					this.SendPropertyChanging();
					this._HarvestFlag = value;
					this.SendPropertyChanged("HarvestFlag");
					this.OnHarvestFlagChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.AssociationAttribute(Name="Repository_CustomerRepository", Storage="_CustomerRepositories", ThisKey="Id", OtherKey="Repository")]
		public EntitySet<CustomerRepository> CustomerRepositories
		{
			get
			{
				return this._CustomerRepositories;
			}
			set
			{
				this._CustomerRepositories.Assign(value);
			}
		}
		
		public event PropertyChangingEventHandler PropertyChanging;
		
		public event PropertyChangedEventHandler PropertyChanged;
		
		protected virtual void SendPropertyChanging()
		{
			if ((this.PropertyChanging != null))
			{
				this.PropertyChanging(this, emptyChangingEventArgs);
			}
		}
		
		protected virtual void SendPropertyChanged(String propertyName)
		{
			if ((this.PropertyChanged != null))
			{
				this.PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
			}
		}
		
		private void attach_CustomerRepositories(CustomerRepository entity)
		{
			this.SendPropertyChanging();
			entity.Repository1 = this;
		}
		
		private void detach_CustomerRepositories(CustomerRepository entity)
		{
			this.SendPropertyChanging();
			entity.Repository1 = null;
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="dbo.CustomerRepository")]
	public partial class CustomerRepository : INotifyPropertyChanging, INotifyPropertyChanged
	{
		
		private static PropertyChangingEventArgs emptyChangingEventArgs = new PropertyChangingEventArgs(String.Empty);
		
		private int _Customer;
		
		private int _Repository;
		
		private EntityRef<Repository> _Repository1;
		
		private EntityRef<Customer> _Customer1;
		
    #region Extensibility Method Definitions
    partial void OnLoaded();
    partial void OnValidate(System.Data.Linq.ChangeAction action);
    partial void OnCreated();
    partial void OnCustomerChanging(int value);
    partial void OnCustomerChanged();
    partial void OnRepositoryChanging(int value);
    partial void OnRepositoryChanged();
    #endregion
		
		public CustomerRepository()
		{
			this._Repository1 = default(EntityRef<Repository>);
			this._Customer1 = default(EntityRef<Customer>);
			OnCreated();
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Customer", DbType="Int NOT NULL", IsPrimaryKey=true)]
		public int Customer
		{
			get
			{
				return this._Customer;
			}
			set
			{
				if ((this._Customer != value))
				{
					if (this._Customer1.HasLoadedOrAssignedValue)
					{
						throw new System.Data.Linq.ForeignKeyReferenceAlreadyHasValueException();
					}
					this.OnCustomerChanging(value);
					this.SendPropertyChanging();
					this._Customer = value;
					this.SendPropertyChanged("Customer");
					this.OnCustomerChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Repository", DbType="Int NOT NULL", IsPrimaryKey=true)]
		public int Repository
		{
			get
			{
				return this._Repository;
			}
			set
			{
				if ((this._Repository != value))
				{
					if (this._Repository1.HasLoadedOrAssignedValue)
					{
						throw new System.Data.Linq.ForeignKeyReferenceAlreadyHasValueException();
					}
					this.OnRepositoryChanging(value);
					this.SendPropertyChanging();
					this._Repository = value;
					this.SendPropertyChanged("Repository");
					this.OnRepositoryChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.AssociationAttribute(Name="Repository_CustomerRepository", Storage="_Repository1", ThisKey="Repository", OtherKey="Id", IsForeignKey=true)]
		public Repository Repository1
		{
			get
			{
				return this._Repository1.Entity;
			}
			set
			{
				Repository previousValue = this._Repository1.Entity;
				if (((previousValue != value) 
							|| (this._Repository1.HasLoadedOrAssignedValue == false)))
				{
					this.SendPropertyChanging();
					if ((previousValue != null))
					{
						this._Repository1.Entity = null;
						previousValue.CustomerRepositories.Remove(this);
					}
					this._Repository1.Entity = value;
					if ((value != null))
					{
						value.CustomerRepositories.Add(this);
						this._Repository = value.Id;
					}
					else
					{
						this._Repository = default(int);
					}
					this.SendPropertyChanged("Repository1");
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.AssociationAttribute(Name="Customer_CustomerRepository", Storage="_Customer1", ThisKey="Customer", OtherKey="Id", IsForeignKey=true)]
		public Customer Customer1
		{
			get
			{
				return this._Customer1.Entity;
			}
			set
			{
				Customer previousValue = this._Customer1.Entity;
				if (((previousValue != value) 
							|| (this._Customer1.HasLoadedOrAssignedValue == false)))
				{
					this.SendPropertyChanging();
					if ((previousValue != null))
					{
						this._Customer1.Entity = null;
						previousValue.CustomerRepositories.Remove(this);
					}
					this._Customer1.Entity = value;
					if ((value != null))
					{
						value.CustomerRepositories.Add(this);
						this._Customer = value.Id;
					}
					else
					{
						this._Customer = default(int);
					}
					this.SendPropertyChanged("Customer1");
				}
			}
		}
		
		public event PropertyChangingEventHandler PropertyChanging;
		
		public event PropertyChangedEventHandler PropertyChanged;
		
		protected virtual void SendPropertyChanging()
		{
			if ((this.PropertyChanging != null))
			{
				this.PropertyChanging(this, emptyChangingEventArgs);
			}
		}
		
		protected virtual void SendPropertyChanged(String propertyName)
		{
			if ((this.PropertyChanged != null))
			{
				this.PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="dbo.Customer")]
	public partial class Customer : INotifyPropertyChanging, INotifyPropertyChanged
	{
		
		private static PropertyChangingEventArgs emptyChangingEventArgs = new PropertyChangingEventArgs(String.Empty);
		
		private int _Id;
		
		private string _Code;
		
		private string _Description;
		
		private string _URL;
		
		private System.Nullable<bool> _HarvestFlag;
		
		private EntitySet<CustomerRepository> _CustomerRepositories;
		
    #region Extensibility Method Definitions
    partial void OnLoaded();
    partial void OnValidate(System.Data.Linq.ChangeAction action);
    partial void OnCreated();
    partial void OnIdChanging(int value);
    partial void OnIdChanged();
    partial void OnCodeChanging(string value);
    partial void OnCodeChanged();
    partial void OnDescriptionChanging(string value);
    partial void OnDescriptionChanged();
    partial void OnURLChanging(string value);
    partial void OnURLChanged();
    partial void OnHarvestFlagChanging(System.Nullable<bool> value);
    partial void OnHarvestFlagChanged();
    #endregion
		
		public Customer()
		{
			this._CustomerRepositories = new EntitySet<CustomerRepository>(new Action<CustomerRepository>(this.attach_CustomerRepositories), new Action<CustomerRepository>(this.detach_CustomerRepositories));
			OnCreated();
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Id", AutoSync=AutoSync.OnInsert, DbType="Int NOT NULL IDENTITY", IsPrimaryKey=true, IsDbGenerated=true)]
		public int Id
		{
			get
			{
				return this._Id;
			}
			set
			{
				if ((this._Id != value))
				{
					this.OnIdChanging(value);
					this.SendPropertyChanging();
					this._Id = value;
					this.SendPropertyChanged("Id");
					this.OnIdChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Code", DbType="NVarChar(50) NOT NULL", CanBeNull=false)]
		public string Code
		{
			get
			{
				return this._Code;
			}
			set
			{
				if ((this._Code != value))
				{
					this.OnCodeChanging(value);
					this.SendPropertyChanging();
					this._Code = value;
					this.SendPropertyChanged("Code");
					this.OnCodeChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_Description", DbType="NVarChar(255) NOT NULL", CanBeNull=false)]
		public string Description
		{
			get
			{
				return this._Description;
			}
			set
			{
				if ((this._Description != value))
				{
					this.OnDescriptionChanging(value);
					this.SendPropertyChanging();
					this._Description = value;
					this.SendPropertyChanged("Description");
					this.OnDescriptionChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_URL", DbType="NVarChar(500)")]
		public string URL
		{
			get
			{
				return this._URL;
			}
			set
			{
				if ((this._URL != value))
				{
					this.OnURLChanging(value);
					this.SendPropertyChanging();
					this._URL = value;
					this.SendPropertyChanged("URL");
					this.OnURLChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_HarvestFlag", DbType="Bit")]
		public System.Nullable<bool> HarvestFlag
		{
			get
			{
				return this._HarvestFlag;
			}
			set
			{
				if ((this._HarvestFlag != value))
				{
					this.OnHarvestFlagChanging(value);
					this.SendPropertyChanging();
					this._HarvestFlag = value;
					this.SendPropertyChanged("HarvestFlag");
					this.OnHarvestFlagChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.AssociationAttribute(Name="Customer_CustomerRepository", Storage="_CustomerRepositories", ThisKey="Id", OtherKey="Customer")]
		public EntitySet<CustomerRepository> CustomerRepositories
		{
			get
			{
				return this._CustomerRepositories;
			}
			set
			{
				this._CustomerRepositories.Assign(value);
			}
		}
		
		public event PropertyChangingEventHandler PropertyChanging;
		
		public event PropertyChangedEventHandler PropertyChanged;
		
		protected virtual void SendPropertyChanging()
		{
			if ((this.PropertyChanging != null))
			{
				this.PropertyChanging(this, emptyChangingEventArgs);
			}
		}
		
		protected virtual void SendPropertyChanged(String propertyName)
		{
			if ((this.PropertyChanged != null))
			{
				this.PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
			}
		}
		
		private void attach_CustomerRepositories(CustomerRepository entity)
		{
			this.SendPropertyChanging();
			entity.Customer1 = this;
		}
		
		private void detach_CustomerRepositories(CustomerRepository entity)
		{
			this.SendPropertyChanging();
			entity.Customer1 = null;
		}
	}
	
	public partial class AddBookmarkResult
	{
		
		private int _Column1;
		
		public AddBookmarkResult()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="", Storage="_Column1", DbType="Int NOT NULL")]
		public int Column1
		{
			get
			{
				return this._Column1;
			}
			set
			{
				if ((this._Column1 != value))
				{
					this._Column1 = value;
				}
			}
		}
	}
	
	public partial class AddBranchResult
	{
		
		private int _Column1;
		
		public AddBranchResult()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="", Storage="_Column1", DbType="Int NOT NULL")]
		public int Column1
		{
			get
			{
				return this._Column1;
			}
			set
			{
				if ((this._Column1 != value))
				{
					this._Column1 = value;
				}
			}
		}
	}
	
	public partial class AddChangesetResult
	{
		
		private int _Column1;
		
		public AddChangesetResult()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="", Storage="_Column1", DbType="Int NOT NULL")]
		public int Column1
		{
			get
			{
				return this._Column1;
			}
			set
			{
				if ((this._Column1 != value))
				{
					this._Column1 = value;
				}
			}
		}
	}
	
	public partial class AddRepositoryEntryResult
	{
		
		private int _Column1;
		
		public AddRepositoryEntryResult()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="", Storage="_Column1", DbType="Int NOT NULL")]
		public int Column1
		{
			get
			{
				return this._Column1;
			}
			set
			{
				if ((this._Column1 != value))
				{
					this._Column1 = value;
				}
			}
		}
	}
	
	public partial class AddPortalResult
	{
		
		private int _Column1;
		
		public AddPortalResult()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="", Storage="_Column1", DbType="Int NOT NULL")]
		public int Column1
		{
			get
			{
				return this._Column1;
			}
			set
			{
				if ((this._Column1 != value))
				{
					this._Column1 = value;
				}
			}
		}
	}
}
#pragma warning restore 1591
