//
//  ViewController.swift
//  AngularVelocitySensor
//
//  Created by Liangshuang WHU on 2021/3/26.
//

import UIKit
import CoreMotion
import Charts
import SwiftUI
import xlsxwriter

var whetherIsOn : Bool = false
class ViewController: UIViewController, ChartViewDelegate {
    
    public var screenWidth : CGFloat {
        return UIScreen.main.bounds.width
    }
    //获取屏幕宽度数据
    
    @IBOutlet weak var textView : UITextView!
    //显示数据
    
    @IBAction func btn1(_ sender: Any) {
        resetData()
    }
    //复位数据
    @IBAction func btn2(_ sender: Any) {
        outputData()
    }
    //输出xls表格
    let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    var uiswitch : UISwitch!;
    
    let motionManager = CMMotionManager()
    
    //刷新时间间隔
        let timeInterval: TimeInterval = 0.1
        var charView:LineChartView?
        var xAxis:XAxis?
    
    override func viewDidLoad() {
            super.viewDidLoad()
    //角速度感应器
        let labelSensor = UILabel()
        labelSensor.frame = CGRect(origin:CGPoint(x:0,y:50), size: CGSize(width:screenWidth,height:100))
        labelSensor.text = "角速度感应器"
        labelSensor.textColor = UIColor.white
        labelSensor.font=UIFont.boldSystemFont(ofSize: 32)
        labelSensor.textAlignment = NSTextAlignment.center
        self.view.addSubview(labelSensor)
        
        let labelSensorE = UILabel()
        labelSensorE.frame = CGRect(origin:CGPoint(x:0,y:90), size: CGSize(width:screenWidth,height:100))
        labelSensorE.text = "Angular Velocity Sensor"
        labelSensorE.textColor = UIColor.white
        labelSensorE.font=UIFont.boldSystemFont(ofSize: 28)
        labelSensorE.textAlignment = NSTextAlignment.center
        self.view.addSubview(labelSensorE)
        
    //开关
                uiswitch = UISwitch()
                //设置位置（开关大小无法设置）
                uiswitch.center = CGPoint(x:screenWidth/2, y:680)
                //设置默认值
                uiswitch.isOn = false;
                uiswitch.addTarget(self, action: #selector(switchDidChange), for:.valueChanged)
                self.view.addSubview(uiswitch)
        
   //开关后标签
        let labelswitch = UILabel()
        labelswitch.frame = CGRect(origin: CGPoint(x:200,y:690),size: CGSize(width:screenWidth,height:20))
        labelswitch.center = CGPoint(x:screenWidth/2,y:700)
        labelswitch.text = "采集数据"
        labelswitch.textColor = UIColor.white
        labelswitch.textAlignment = NSTextAlignment.center
        labelswitch.font=UIFont.systemFont(ofSize: 8)
        self.view.addSubview(labelswitch)
        
            //表格
            charView = LineChartView(frame: CGRect(x: 0, y: 300, width: 400, height: 200))
            charView!.delegate = self
                    charView!.chartDescription?.enabled = true
                    charView!.dragEnabled = true
                    charView!.setScaleEnabled(true)
                    charView!.pinchZoomEnabled = true
                    charView!.drawGridBackgroundEnabled = false
                    charView!.highlightPerDragEnabled = true
                    charView!.backgroundColor = UIColor.black
                    charView!.legend.enabled = true
                    
                    xAxis = charView?.xAxis
                    xAxis!.labelPosition = XAxis.LabelPosition.bottom
                    xAxis!.labelFont = UIFont(name: "HelveticaNeue", size: 10)!
                    xAxis!.labelTextColor = UIColor(red: 255/255.0, green: 192/255.0, blue: 56/255.0, alpha: 1.0)
                    xAxis!.drawAxisLineEnabled = true
                    xAxis!.drawGridLinesEnabled = true
                    xAxis!.centerAxisLabelsEnabled = true
                    xAxis!.granularity = 3600.0
        
                    
                    charView!.rightAxis.enabled = false
                    charView!.legend.form = Legend.Form.line
                    
                    self.view.addSubview(charView!)
                    
                    startGyroUpdates()
        }
    var rotationRateZ : [Double] = []
    var TotalTime : TimeInterval = 0
    
    // 开始获取陀螺仪数据
    func startGyroUpdates()
       {
           //判断设备支持情况
           guard motionManager.isGyroAvailable else {
               self.textView.text = "\n当前设备不支持陀螺仪\n"
               return
           }
        
        var rotationRate: CMRotationRate
           //设置刷新时间间隔
           self.motionManager.gyroUpdateInterval = self.timeInterval
           //开始实时获取数据
           let queue = OperationQueue.current
        self.motionManager.startGyroUpdates(to: queue!, withHandler:{ [self] (gyroData, error) in
               guard error == nil else {
                   print(error!)
                   return
               }
               // 有更新
            
            if self.motionManager.isGyroActive {
                if let rotationRate = gyroData?.rotationRate {
                       var text = "当前陀螺仪数据\n"
                       text += "Current Angular Velocity\n"
                       text += "\(rotationRate.z)\n"
                       self.textView.text = text
                    
                    if (whetherIsOn == true){
                        rotationRateZ.append(Double(rotationRate.z))
                        TotalTime += 0.1
                        draw_pic()
                    }
                   }
               }
           })
       }
    
    @objc func switchDidChange(){
        if (uiswitch.isOn == true){
            whetherIsOn = true
        }
        
        if (uiswitch.isOn == false) {
            whetherIsOn = false
        }
    }
    
    func draw_pic() {
        
        var values:[ChartDataEntry] = []
        var x: Double = 0
        var counter : Int = 0
            while x < TotalTime {
                values.append(ChartDataEntry(x: x, y: rotationRateZ[counter]))
                x += 0.1
                counter += 1
            }
            
            var set1:LineChartDataSet?
            set1 = LineChartDataSet(entries: values, label: "角速度数据")
            set1!.axisDependency = YAxis.AxisDependency.left
            set1!.valueTextColor = UIColor(red: 51/255.0, green: 181/255.0, blue: 229/255.0, alpha: 1.0)
            set1!.lineWidth = 1.5
            set1!.drawCirclesEnabled = false
            set1!.drawValuesEnabled = true
            set1!.fillAlpha = 0.26
            set1!.fillColor = UIColor(red: 51/255.0, green: 181/255.0, blue: 229/255.0, alpha: 1.0)
            set1!.highlightColor = UIColor(red: 224/255.0, green: 117/255.0, blue: 117/255.0, alpha: 1.0)
            set1!.drawCircleHoleEnabled = false
        
    
    var dataSets:[ChartDataSet] = []
            dataSets.append(set1!)
            
            let data:LineChartData! = LineChartData(dataSets: dataSets)
            data.setValueTextColor(UIColor.white)
            charView?.data = data
            
            if charView!.data!.dataSetCount > 0 {
                set1 = charView!.data?.dataSets[0] as! LineChartDataSet?
                charView!.data?.notifyDataChanged()
                charView!.notifyDataSetChanged()
            }
    }
    
    func resetData(){
        TotalTime = 0
        rotationRateZ.removeAll()
        draw_pic()
    }

    func outputData(){
        
        let jsonPath = (docDir as NSString).appendingPathComponent("AngularVelocityData.xlsx")
        let book = workbook_new(jsonPath)
        let sheet = workbook_add_worksheet(book, "sheet1")
        
        var counter : Int = 0
        var x : Double = 0
        worksheet_write_string(sheet, 0, 0,"Time", nil)
        worksheet_write_string(sheet, 0, 1,"AngularVelocity",nil)
        
        while x < TotalTime {
            worksheet_write_number(sheet, lxw_row_t(counter+1), 0,x,nil)
            worksheet_write_number(sheet, lxw_row_t(counter+1), 1,rotationRateZ[counter],nil)
            x += 0.1
            counter += 1
        }
        
        workbook_close(book);
        print(jsonPath)
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            print("chartValueSelected")
        }
        
        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            print("chartValueNothingSelected")
        }
    
       override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
       }
}

