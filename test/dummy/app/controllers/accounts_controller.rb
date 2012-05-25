
class AccountsController < ApplicationController

  belongs_to :client

  # GET /clients/1/accounts
  # GET /clients/1/accounts.json
  def index
    @accounts = resource.relation.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @accounts }
    end
  end

  # GET /clients/1/accounts/1
  # GET /clients/1/accounts/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account }
    end
  end

  # GET /clients/1/accounts/new
  # GET /clients/1/accounts/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account }
    end
  end

  # GET /clients/1/accounts/1/edit
  def edit
  end

  # POST /clients/1/accounts
  # POST /clients/1/accounts.json
  def create
    respond_to do |format|
      if @account.save
        format.html { redirect_to client_account_path(@account.client,@account), notice: 'Account was successfully created.' }
        format.json { render json: @account, status: :created, location: @account }
      else
        format.html { render action: "new" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /clients/1/accounts/1
  # PUT /clients/1/accounts/1.json
  def update
    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html { redirect_to client_account_path(@account), notice: 'Account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1/accounts/1
  # DELETE /clients/1/accounts/1.json
  def destroy
    @account.destroy

    respond_to do |format|
      format.html { redirect_to client_accounts_url }
      format.json { head :no_content }
    end
  end
end
