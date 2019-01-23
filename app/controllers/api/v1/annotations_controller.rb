module Api
  module V1
    class AnnotationsController < ApplicationController
      respond_to :json

      def index
        @annotation = Annotation.where.not(item_price_dup: 0)
        @annotation = @annotation.where.not("date_status =? AND date < ?","order",Date.today )

        graph_data = 0.0
        stocks = StockQuote::Stock.quote("aapl").as_json
        stock_price = stocks["latest_price"]
        item_name = ""
        item_price = 0
        item_merchant = ""
        item_user = ""
        invoice = ""

        if @annotation.present? 
          @annotation.each do |x|
            if x.date.to_date == Date.today
              @share = Share.find_by("investment_principal_dup > ?", 0)
              investment_principal = @share.try(:investment_principal_dup)

              item_price = x.Item_Price
              item_name = x.Item_Name
              item_merchant = x.Merchant_Name
              item_user = User.find_by_id(x.annotation_creator_id).first_name + User.find_by_id(x.annotation_creator_id).last_name
              invoice = x.Note
              temp_item_name = item_name.split('')

              i=0
              temp_str = ''
              temp_item_name.each do |ch|
                if (temp_item_name[i] == temp_item_name[i].downcase && temp_item_name[i+1]==temp_item_name[i+1].upcase)
                    temp_str += ' '
                end
                temp_str += ch
                i+=1
                
                if i>=temp_item_name.length-1
                    temp_str +=temp_item_name[i]
                    break
                end
              end
              # space added in array
              item_name = temp_str

              if @share.present? &&  @share.investment_principal_dup >= x.item_price_dup
                investment_principal = investment_principal - x.item_price_dup
                x.update(item_price_dup: 0)
                @share.update(investment_principal_dup: investment_principal)
              elsif @share.present? && x.item_price_dup > investment_principal
                val = x.item_price_dup - investment_principal
                x.update(item_price_dup: val)
                @share.update(investment_principal_dup: 0)
              end
            end
          end
        end

        total_fulfilled_requests = Annotation.where(item_price_dup: 0).count
        avg = (Annotation.where(item_price_dup: 0).pluck(:Item_Price).compact.sum.to_f / total_fulfilled_requests.to_f) if total_fulfilled_requests > 0
        graph_data = avg > stock_price.to_f ? (avg/stock_price).round(4) : (stock_price/avg).round(4) if avg > 0.0
        if params[:is_candlestick]
          previous_graph_hash = { x_axis: params[:x_axis], open: params[:open], high: params[:high], low: params[:low], close: params[:close], volume: params[:volume] }
          Graph.last.update_columns(previous_graph_hash) if Graph.count > 0
          Graph.create!(graph_data: graph_data.to_f.round(4),item_name: item_name,item_price: item_price,vendor: item_merchant,user: item_user,invoice: invoice)
        end
        return render json: { new_price: graph_data.to_f.round(4), total_fulfilled_requests: total_fulfilled_requests } unless params[:initial]
        points_to_show = Graph.order('created_at DESC').where.not(x_axis: nil).limit(20).select(:x_axis, :open, :high, :low, :close, :volume)
        fulfilled_avg = points_to_show.map{|graph| [graph.x_axis.to_i, graph.open, graph.high, graph.low, graph.close]}.reverse
        volumes = points_to_show.map{|graph| [graph.x_axis.to_i, graph.volume.to_i]}.reverse
        render json: {fulfilled_avg: fulfilled_avg, total_fulfilled_requests: volumes}
      end
    end
  end
end
