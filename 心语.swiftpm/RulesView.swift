import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 标题和关闭按钮
                HStack {
                    Text("NMO 游戏规则")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // 规则内容
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Group {
                            Text("游戏目标")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("成为第一个出完所有手牌的玩家。")
                                .foregroundColor(.white)
                            
                            Text("卡牌类型")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("• 数字牌 (0-9): 按照数字和颜色匹配出牌")
                                .foregroundColor(.white)
                            Text("• 跳过牌 (⏭): 让对手跳过一个回合，对手不能出牌")
                                .foregroundColor(.white)
                            Text("• 反转牌 (↩️): 在双人游戏中相当于跳过牌，改变出牌顺序")
                                .foregroundColor(.white)
                            Text("• +2牌: 对手必须抽两张牌，并且跳过回合")
                                .foregroundColor(.white)
                            Text("• 变色牌 (🎨): 可以改变当前颜色，选择任意颜色继续游戏")
                                .foregroundColor(.white)
                            Text("• +4变色牌: 对手必须抽四张牌，并且可以改变当前颜色")
                                .foregroundColor(.white)
                        }
                        
                        Group {
                            Text("游戏规则")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top)
                            
                            Text("1. 每位玩家开始时有7张牌")
                                .foregroundColor(.white)
                            Text("2. 玩家必须打出与弃牌堆顶部卡牌颜色、数字或符号相匹配的牌")
                                .foregroundColor(.white)
                            Text("3. 如果没有可以打出的牌，必须从牌堆抽一张牌")
                                .foregroundColor(.white)
                            Text("4. 当你只剩下一张牌时，应该喊'NMO'")
                                .foregroundColor(.white)
                            Text("5. 第一个出完所有手牌的玩家获胜")
                                .foregroundColor(.white)
                            Text("6. 特殊规则：")
                                .foregroundColor(.white)
                                .padding(.top, 5)
                            Text("   • 如果抽到的牌可以打出，可以选择立即打出")
                                .foregroundColor(.white)
                            Text("   • 变色牌和+4变色牌可以在任何时候打出")
                                .foregroundColor(.white)
                            Text("   • 如果牌堆用完，将弃牌堆洗牌后继续使用")
                                .foregroundColor(.white)
                        }
                        
                        // 卡牌示例
                        Text("卡牌示例")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        HStack(spacing: 10) {
                            ForEach(CardColor.allCases.filter { $0 != .wild }, id: \.self) { color in
                                CardView(
                                    card: Card(color: color, type: .number, value: 5),
                                    width: 60,
                                    height: 90,
                                    isPlayable: false
                                )
                            }
                        }
                        .padding(.vertical)
                        
                        HStack(spacing: 10) {
                            CardView(
                                card: Card(color: .red, type: .skip, value: -1),
                                width: 60,
                                height: 90,
                                isPlayable: false
                            )
                            
                            CardView(
                                card: Card(color: .blue, type: .reverse, value: -1),
                                width: 60,
                                height: 90,
                                isPlayable: false
                            )
                            
                            CardView(
                                card: Card(color: .green, type: .drawTwo, value: -1),
                                width: 60,
                                height: 90,
                                isPlayable: false
                            )
                            
                            CardView(
                                card: Card(color: .wild, type: .wild, value: -1),
                                width: 60,
                                height: 90,
                                isPlayable: false
                            )
                            
                            CardView(
                                card: Card(color: .wild, type: .wildDrawFour, value: -1),
                                width: 60,
                                height: 90,
                                isPlayable: false
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
} 