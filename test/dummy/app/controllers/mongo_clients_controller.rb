# Copyright (c) 2012 Bingo Entreprenøren AS
# Copyright (c) 2012 Teknobingo Scandinavia AS
# Copyright (c) 2012 Knut I. Stenmark
# Copyright (c) 2012 Patrick Hanevold
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class MongoClientsController < ApplicationController
  # GET /clients
  # GET /clients.json
  def index
    @mongo_clients = MongoClient.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mongo_clients }
    end
  end

  # GET /clients/1
  # GET /clients/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mongo_client }
    end
  end

  # GET /clients/new
  # GET /clients/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mongo_client }
    end
  end

  # POST /clients
  # POST /clients.json
  def create
    respond_to do |format|
      if @mongo_client.save
        format.html { redirect_to @mongo_client, notice: 'MongoClient was successfully created.' }
        format.json { render json: @mongo_client, status: :created, location: @client }
      else
        format.html { render action: "new" }
        format.json { render json: @mongo_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /clients/1
  # PUT /clients/1.json
  def update
    respond_to do |format|
      if @mongo_client.update_attributes(resource.strong_params)
        format.html { redirect_to @mongo_client, notice: 'Client was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @mongo_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1
  # DELETE /clients/1.json
  def destroy
    @mongo_client = MongoClient.find(params[:id])
    @mongo_client.destroy

    respond_to do |format|
      format.html { redirect_to mongo_clients_url }
      format.json { head :no_content }
    end
  end
end
