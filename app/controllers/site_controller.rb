require 'net/http'
require 'rexml/document'

include REXML
class SiteController < ApplicationController
  def home
  end

  def about
  end

  def timer
    @stations = Station.find(:all)
  end

  def dotimer
    #Store Phone Number
    number = params[:phone]
    #Store the Communication prefrence Type
    commtype = params[:comms]
    #Build the URL containing the Selected Stations Code
    url = "http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML_WithNumMins?StationCode=#{params[:name]}+&NumMins=30"
    #Get the Response from the Irish Rail REST API
    data = Net::HTTP.get_response(URI.parse(url)).body
    if number[0..1]="08"
      number[0] ="+353"
    end
    #Create the REXML Document
    doc = Document.new(data)
    dests = XPath.match(doc, "//Destination").map{|dest| dest.text}
    status = XPath.match(doc, "//Status").map{|stat| stat.text}
    due = XPath.match(doc, "//Duein").map{|duein| duein.text}
    dir = XPath.match(doc, "//Direction").map{|d| d.text}
    size = dests.length - 1
    @output = "<table border=\"1\" style=\"width:100%; text-align: center\"><tr><th /><th>Information</th><th>Due In</th>"
    for i in 0..size
      @output="#{@output} <tr><td><img src=\"train.png\" width=\"30\" height=\"30\" /></td><td>Dart traveling #{dir.at(i)} going to #{dests.at(i)}</td><td>#{due.at(i)} Minutes</td></tr>"
    end
    @output="#{@output} </table>"
    payload = "Trains due at your Selected Station: "
    if commtype == '0'
      for i in 0..size
        if payload.size<110
          payload = "#{payload} #{i+1}. Train to #{dests.at(i)} due in #{due.at(i)} Minutes."
        end
      end
      ExtComms::ExtComms.new.sendSMS(number,payload)
    elsif commtype == '1'
      payload ="Welcome to Train Timer</Say>"
      for i in 0..size
        payload="#{payload}<pause length=\"1\"/><Say>#{i+1}. Train to #{dests.at(i)} due in #{due.at(i)} Minutes.</Say>"
      end
      payload = "#{payload}<pause length=\"1\"/><Say>Thank you for using Train-Timer"
      ExtComms::ExtComms.new.doCall(number,payload)
    end
  end
end
