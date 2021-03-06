require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'

module Spree
  module Admin
    class StockBoxesController < ResourceController #Spree::Admin::BaseController
      
      # GET /stock_boxes
      # GET /stock_boxes.json
      def index
        @stock_boxes = StockBox.all

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @stock_boxes }
        end
      end
      
      # GET /stock_boxes/1
      # GET /stock_boxes/1.json
      def show
        @stock_box = StockBox.find(params[:id])
        @variants = @stock_box.variants
        
        @barcode_path = "/tmp/barcode_stockbox_#{@stock_box.number}.png"
        unless FileTest.exist?("#{Rails.root}/public#{@barcode_path}")
          barcode = Barby::Code128A.new(@stock_box.number)
          File.open("#{Rails.root}/public#{@barcode_path}", 'w+') do |f|
            f.write barcode.to_png(:margin => 3, :xdim => 2, :height => 65)
          end
        end
        
        respond_to do |format|
          format.html # show.html.erb
          format.json { render json: @stock_box }
        end
      end

      # GET /stock_boxes/new
      # GET /stock_boxes/new.json
      def new
        @stock_box = StockBox.new

        respond_to do |format|
          format.html # new.html.erb
          format.json { render json: @stock_box }
        end
      end

      # GET /stock_boxes/1/edit
      def edit
        @stock_box = StockBox.find(params[:id])
      end

      # POST /stock_boxes
      # POST /stock_boxes.json
      def create
        @stock_box = StockBox.new(params[:stock_box])

        respond_to do |format|
          if @stock_box.save
            format.html { redirect_to admin_stock_boxes_url, notice: 'Caixa de estoque criada com sucesso.' }
            format.json { render json: @stock_box, status: :created, location: @stock_box }
          else
            format.html { render action: "new" }
            format.json { render json: @stock_box.errors, status: :unprocessable_entity }
          end
        end
      end

      # PUT /stock_boxes/1
      # PUT /stock_boxes/1.json
      def update
        @stock_box = StockBox.find(params[:id])

        respond_to do |format|
          if @stock_box.update_attributes(params[:stock_box])
            format.html { redirect_to admin_stock_boxes_url, notice: 'Caixa de estoque atualizada com sucesso.' }
            format.json { head :no_content }
          else
            format.html { render action: "edit" }
            format.json { render json: @stock_box.errors, status: :unprocessable_entity }
          end
        end
      end

      # DELETE /stock_boxes/1
      # DELETE /stock_boxes/1.json
      def destroy
        @stock_box = StockBox.find(params[:id])
        @stock_box.destroy

        respond_to do |format|
          format.html { redirect_to admin_stock_boxes_url }
          format.json { head :no_content }
        end
      end
          
      def stocking

      end

      def stocking_check
        
        @box = StockBox.find_by_number(params[:box_number])
        if params[:field_action] == "open"
          check = "open"  
          respond_to do |format|
            format.js { render "box_open" }
          end
        end

        if params[:field_action] == "insert"
          check = "insert"
          
          @new_image = nil
          registered_items = params[:registered_items]
          new_item = params[:stock_items].split(",").last.squish.downcase
          box_number = params[:box_number].downcase
          @new_value = registered_items
          if new_item == box_number
            respond_to do |format|
              format.js { render "box_close" }
            end      
          else
            
            variant = Spree::Variant.find_by_sku(new_item)
            if variant
              @check_message = 2
              if variant.count_on_hand == 0
                @check_message = 4
                order = variant.product.order
                shipment = order ? order.shipment : nil
                if shipment
                  @check_message = 1 if shipment.state == "shipped" || shipment.state == "ready"
                end
              end
            else
              name = "Produto em processo de cadastramento"
              p = Spree::Product.new(sku: new_item, price: 0, on_hand: 0, name: name, permalink: name.to_url)
              p.save(validate: false)
              @check_message = 3
            end
            
            if @check_message > 1
              new_value = [registered_items, new_item, ","] - [""]
              @new_value = new_value.join("") if new_value
            end

            product = variant.product if variant
            images = product.images if product
            if images && !images.empty?
              attachment = images.first.attachment     
              @new_image = attachment.url(:product) if attachment
            end
            
            respond_to do |format|
              format.js { render "box_insert" }
            end               
          end
          
        end

        if params[:field_action] == "close"
          check = "close"
          registered_items = params[:registered_items]
          registered_items.split(",").each do |v|
            variant = Spree::Variant.find_by_sku(v)
            variant.update_column(:stock_box_id, @box.id)
          end
          respond_to do |format|
            format.js { render "page_reload" }
          end
                    
        end
        
        render nothing: true unless check
      end
      
    end
  end
end
