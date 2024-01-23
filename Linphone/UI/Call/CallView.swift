/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// swiftlint:disable type_body_length
// swiftlint:disable line_length
import SwiftUI
import CallKit
import AVFAudio
import linphonesw

struct CallView: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	@ObservedObject private var telecomManager = TelecomManager.shared
	@ObservedObject private var contactsManager = ContactsManager.shared
	
	@ObservedObject var callViewModel: CallViewModel
	
	private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
	@State private var orientation = UIDevice.current.orientation
	
	let pub = NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
	
	@State var startDate = Date.now
	@State var audioRouteSheet: Bool = false
	@State var hideButtonsSheet: Bool = false
	@State var options: Int = 1
	
	@State var imageAudioRoute: String = ""
	
	@State var angleDegree = 0.0
	@State var fullscreenVideo = false
	
	var body: some View {
		GeometryReader { geo in
			ZStack {
				if #available(iOS 16.0, *), idiom != .pad {
					innerView(geometry: geo)
						.sheet(isPresented: $audioRouteSheet, onDismiss: {
							audioRouteSheet = false
							hideButtonsSheet = false
						}) {
							innerBottomSheet()
								.presentationDetents([.fraction(0.3)])
						}
				} else {
					innerView(geometry: geo)
						.halfSheet(showSheet: $audioRouteSheet) {
							innerBottomSheet()
						} onDismiss: {
							audioRouteSheet = false
							hideButtonsSheet = false
						}
				}
				if callViewModel.zrtpPopupDisplayed == true {
					ZRTPPopup(callViewModel: callViewModel)
						.background(.black.opacity(0.65))
						.onTapGesture {
							callViewModel.zrtpPopupDisplayed = false
						}
				}
			}
		}
	}
	
	@ViewBuilder
	func innerBottomSheet() -> some View {
		VStack(spacing: 0) {
			Button(action: {
				options = 1
				
				do {
					try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
					if callViewModel.isHeadPhoneAvailable() {
						try AVAudioSession.sharedInstance().setPreferredInput(AVAudioSession.sharedInstance().availableInputs?.filter({ $0.portType.rawValue.contains("Receiver") }).first)
					} else {
						try AVAudioSession.sharedInstance().setPreferredInput(AVAudioSession.sharedInstance().availableInputs?.first)
					}
				} catch _ {
					
				}
			}, label: {
				HStack {
					Image(options == 1 ? "radio-button-fill" : "radio-button")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
					
					Text(!callViewModel.isHeadPhoneAvailable() ? "Earpiece" : "Headphones")
						.default_text_style_white(styleSize: 15)
					
					Spacer()
					
					Image(!callViewModel.isHeadPhoneAvailable() ? "ear" : "headset")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
				}
			})
			.frame(maxHeight: .infinity)
			
			Button(action: {
				options = 2
				
				do {
					try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
				} catch _ {
					
				}
			}, label: {
				HStack {
					Image(options == 2 ? "radio-button-fill" : "radio-button")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
					
					Text("Speaker")
						.default_text_style_white(styleSize: 15)
					
					Spacer()
					
					Image("speaker-high")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
				}
			})
			.frame(maxHeight: .infinity)
			
			Button(action: {
				options = 3
				
				do {
					try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
					try AVAudioSession.sharedInstance().setPreferredInput(AVAudioSession.sharedInstance().availableInputs?.filter({ $0.portType.rawValue.contains("Bluetooth") }).first)
				} catch _ {
					
				}
			}, label: {
				HStack {
					Image(options == 3 ? "radio-button-fill" : "radio-button")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
					
					Text("Bluetooth")
						.default_text_style_white(styleSize: 15)
					
					Spacer()
					
					Image("bluetooth")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(.white)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
				}
			})
			.frame(maxHeight: .infinity)
		}
		.padding(.horizontal, 20)
		.background(Color.gray600)
		.frame(maxHeight: .infinity)
	}
	
	@ViewBuilder
	// swiftlint:disable:next cyclomatic_complexity
	func innerView(geometry: GeometryProxy) -> some View {
		VStack {
			if !fullscreenVideo || (fullscreenVideo && telecomManager.isPausedByRemote) {
				if #available(iOS 16.0, *) {
					Rectangle()
						.foregroundColor(Color.orangeMain500)
						.edgesIgnoringSafeArea(.top)
						.frame(height: 0)
				} else if idiom != .pad && !(orientation == .landscapeLeft || orientation == .landscapeRight
											 || UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height) {
					Rectangle()
						.foregroundColor(Color.orangeMain500)
						.edgesIgnoringSafeArea(.top)
						.frame(height: 1)
				}
				
				HStack {
					if callViewModel.direction == .Outgoing {
						Image("outgoing-call")
							.resizable()
							.frame(width: 15, height: 15)
							.padding(.horizontal)
						
						Text("Outgoing call")
							.foregroundStyle(.white)
					} else {
						Image("incoming-call")
							.resizable()
							.frame(width: 15, height: 15)
							.padding(.horizontal)
						
						Text("Incoming call")
							.foregroundStyle(.white)
					}
					
					if !telecomManager.outgoingCallStarted && telecomManager.callInProgress {
						Text("|")
							.foregroundStyle(.white)
						
						ZStack {
							Text(callViewModel.timeElapsed.convertDurationToString())
								.onReceive(callViewModel.timer) { firedDate in
									callViewModel.timeElapsed = Int(firedDate.timeIntervalSince(startDate))
								}
								.foregroundStyle(.white)
								.if(callViewModel.isPaused || telecomManager.isPausedByRemote) { view in
									view.hidden()
								}
							
							if callViewModel.isPaused {
								Text("Paused")
									.foregroundStyle(.white)
							} else if telecomManager.isPausedByRemote {
								Text("Paused by remote")
									.foregroundStyle(.white)
							}
						}
					}
					
					Spacer()
					
					if callViewModel.isMediaEncrypted {
						Button {
							callViewModel.showZrtpSasDialogIfPossible()
						} label: {
							Image(callViewModel.isZrtpPq ? "media-encryption-zrtp-pq" : "media-encryption-srtp")
								.resizable()
								.frame(width: 30, height: 30)
								.padding(.horizontal)
						}
					}
					
					if telecomManager.remoteVideo {
						Button {
							callViewModel.switchCamera()
						} label: {
							Image("camera-rotate")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle(.white)
								.frame(width: 30, height: 30)
								.padding(.horizontal)
						}
					}
				}
				.frame(height: 40)
				.zIndex(1)
			}
			
			ZStack {
				VStack {
					Spacer()
					ZStack {
						
						if callViewModel.isRemoteDeviceTrusted {
							Circle()
								.fill(Color.blueInfo500)
								.frame(width: 105, height: 105)
						}
						
						if callViewModel.remoteAddress != nil {
							let addressFriend = contactsManager.getFriendWithAddress(address: callViewModel.remoteAddress!)
							
							let contactAvatarModel = addressFriend != nil
							? ContactsManager.shared.avatarListModel.first(where: {
								($0.friend!.consolidatedPresence == .Online || $0.friend!.consolidatedPresence == .Busy)
								&& $0.friend!.name == addressFriend!.name
								&& $0.friend!.address!.asStringUriOnly() == addressFriend!.address!.asStringUriOnly()
							})
							: ContactAvatarModel(friend: nil, withPresence: false)
							
							if addressFriend != nil && addressFriend!.photo != nil && !addressFriend!.photo!.isEmpty {
								if contactAvatarModel != nil {
									Avatar(contactAvatarModel: contactAvatarModel!, avatarSize: 100, hidePresence: true)
								}
							} else {
								if callViewModel.remoteAddress!.displayName != nil {
									Image(uiImage: contactsManager.textToImage(
										firstName: callViewModel.remoteAddress!.displayName!,
										lastName: callViewModel.remoteAddress!.displayName!.components(separatedBy: " ").count > 1
										? callViewModel.remoteAddress!.displayName!.components(separatedBy: " ")[1]
										: ""))
									.resizable()
									.frame(width: 100, height: 100)
									.clipShape(Circle())
									
								} else {
									Image(uiImage: contactsManager.textToImage(
										firstName: callViewModel.remoteAddress!.username ?? "Username Error",
										lastName: callViewModel.remoteAddress!.username!.components(separatedBy: " ").count > 1
										? callViewModel.remoteAddress!.username!.components(separatedBy: " ")[1]
										: ""))
									.resizable()
									.frame(width: 100, height: 100)
									.clipShape(Circle())
								}
								
							}
						} else {
							Image("profil-picture-default")
								.resizable()
								.frame(width: 100, height: 100)
								.clipShape(Circle())
						}
						
						if callViewModel.isRemoteDeviceTrusted {
							VStack {
								Spacer()
								HStack {
									Image("trusted")
										.resizable()
										.frame(width: 25, height: 25)
									Spacer()
								}
							}
							.frame(width: 100, height: 100)
						}
					}
					
					Text(callViewModel.displayName)
						.padding(.top)
						.foregroundStyle(.white)
					
					Text(callViewModel.remoteAddressString)
						.foregroundStyle(.white)
					
					Spacer()
				}
				
				LinphoneVideoViewHolder { view in
					coreContext.doOnCoreQueue { core in
						core.nativeVideoWindow = view
					}
				}
				.frame(
					width:
						angleDegree == 0
					? 120 * ((geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom) / 160)
					: 120 * ((geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) / 120),
					height:
						angleDegree == 0
					? 160 * ((geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom) / 160)
					: 160 * ((geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) / 120)
				)
				.scaledToFill()
				.clipped()
				.onTapGesture {
					if telecomManager.remoteVideo {
						fullscreenVideo.toggle()
					}
				}
				
				if telecomManager.remoteVideo {
					HStack {
						Spacer()
						VStack {
							Spacer()
							LinphoneVideoViewHolder { view in
								coreContext.doOnCoreQueue { core in
									core.nativePreviewWindow = view
								}
							}
							.frame(width: angleDegree == 0 ? 120*1.2 : 160*1.2, height: angleDegree == 0 ? 160*1.2 : 120*1.2)
							.cornerRadius(20)
							.padding(10)
							.padding(.trailing, abs(angleDegree/2))
						}
					}
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - 140
					)
				}
				
				if callViewModel.isRecording {
					HStack {
						VStack {
							Image("record-fill")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle(Color.redDanger500)
								.frame(width: 32, height: 32)
								.padding(10)
								.if(fullscreenVideo && !telecomManager.isPausedByRemote) { view in
									view.padding(.top, 30)
								}
							Spacer()
						}
						Spacer()
					}
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - 140
					)
				}
				
				if  telecomManager.outgoingCallStarted {
					VStack {
						ActivityIndicator()
							.frame(width: 20, height: 20)
							.padding(.top, 100)
						
						Text(callViewModel.counterToMinutes())
							.onAppear {
								callViewModel.timeElapsed = 0
								startDate = Date.now
							}
							.onReceive(callViewModel.timer) { firedDate in
								callViewModel.timeElapsed = Int(firedDate.timeIntervalSince(startDate))
								
							}
							.onDisappear {
								callViewModel.timeElapsed = 0
								startDate = Date.now
							}
							.padding(.top)
							.foregroundStyle(.white)
						
						Spacer()
					}
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (0.1 * geometry.size.height) - 60
					)
					.background(.clear)
				}
			}
			.frame(
				maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
				maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (0.1 * geometry.size.height) - 60
			)
			.background(Color.gray600)
			.cornerRadius(20)
			.padding(.horizontal, fullscreenVideo && !telecomManager.isPausedByRemote ? 0 : 4)
			.onRotate { newOrientation in
				let oldOrientation = orientation
				orientation = newOrientation
				if orientation == .portrait || orientation == .portraitUpsideDown {
					angleDegree = 0
				} else {
					if orientation == .landscapeLeft {
						angleDegree = -90
					} else if orientation == .landscapeRight {
						angleDegree = 90
					}
				}
				
				if (oldOrientation != orientation && oldOrientation != .faceUp) || (oldOrientation == .faceUp && (orientation == .landscapeLeft || orientation == .landscapeRight)) {
					telecomManager.callStarted = false
					
					DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
						telecomManager.callStarted = true
					}
				}
				
				callViewModel.orientationUpdate(orientation: orientation)
			}
			.onAppear {
				if orientation == .portrait && orientation == .portraitUpsideDown {
					angleDegree = 0
				} else {
					if orientation == .landscapeLeft {
						angleDegree = -90
					} else if orientation == .landscapeRight {
						angleDegree = 90
					}
				}
				
				telecomManager.callStarted = false
				
				DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
					telecomManager.callStarted = true
				}
				
				callViewModel.orientationUpdate(orientation: orientation)
			}
			
			if !fullscreenVideo || (fullscreenVideo && telecomManager.isPausedByRemote) {
				if telecomManager.callStarted {
					let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
					let bottomInset = scene?.windows.first?.safeAreaInsets
					
					BottomSheetView(
						content: bottomSheetContent(geo: geometry),
						minHeight: (0.1 * geometry.size.height) + (bottomInset != nil ? bottomInset!.bottom : 0),
						maxHeight: (0.45 * geometry.size.height) + (bottomInset != nil ? bottomInset!.bottom : 0),
						currentHeight: (0.1 * geometry.size.height) + (bottomInset != nil ? bottomInset!.bottom : 0)
					)
				} else {
#if targetEnvironment(simulator)
					HStack(spacing: 12) {
						HStack {
							Spacer()
							
							Button {
								callViewModel.terminateCall()
							} label: {
								Image("phone-disconnect")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 32, height: 32)
								
							}
							.frame(width: 90, height: 60)
							.background(Color.redDanger500)
							.cornerRadius(40)
							
							Button {
								callViewModel.acceptCall()
							} label: {
								Image("phone")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 32, height: 32)
								
							}
							.frame(width: 90, height: 60)
							.background(Color.greenSuccess500)
							.cornerRadius(40)
							
							Spacer()
						}
						.frame(height: 60)
					}
					.padding(.horizontal, 25)
					.padding(.top, 20)
#else
					HStack(spacing: 12) {
						HStack {
						}
						.frame(height: 60)
					}
					.padding(.horizontal, 25)
					.padding(.top, 20)
#endif
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.gray900)
		.if(fullscreenVideo && !telecomManager.isPausedByRemote) { view in
			view.ignoresSafeArea(.all)
		}
	}
	
	func bottomSheetContent(geo: GeometryProxy) -> some View {
		GeometryReader { _ in
			VStack(spacing: 0) {
				Rectangle()
					.fill(Color.gray500)
					.frame(width: 100, height: 5)
					.cornerRadius(10)
					.padding(.top, 5)
				HStack(spacing: 12) {
					Button {
						callViewModel.terminateCall()
					} label: {
						Image("phone-disconnect")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(.white)
							.frame(width: 32, height: 32)
						
					}
					.frame(width: 90, height: 60)
					.background(Color.redDanger500)
					.cornerRadius(40)
					
					Spacer()
					
					Button {
						callViewModel.toggleVideo()
					} label: {
						Image(telecomManager.remoteVideo ? "video-camera" : "video-camera-slash")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
							.frame(width: 32, height: 32)
						
					}
					.frame(width: 60, height: 60)
					.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray600 : Color.gray500)
					.cornerRadius(40)
					.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
					
					Button {
						callViewModel.toggleMuteMicrophone()
					} label: {
						Image(callViewModel.micMutted ? "microphone-slash" : "microphone")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(callViewModel.micMutted ? .black : .white)
							.frame(width: 32, height: 32)
						
					}
					.frame(width: 60, height: 60)
					.background(callViewModel.micMutted ? .white : Color.gray500)
					.cornerRadius(40)
					
					Button {
						if AVAudioSession.sharedInstance().availableInputs != nil
							&& !AVAudioSession.sharedInstance().availableInputs!.filter({ $0.portType.rawValue.contains("Bluetooth") }).isEmpty {
							
							hideButtonsSheet = true
							
							DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
								audioRouteSheet = true
							}
						} else {
							do {
								try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue == "Speaker" }).isEmpty ? .speaker : .none)
							} catch _ {
								
							}
						}
						
					} label: {
						Image(imageAudioRoute)
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(.white)
							.frame(width: 32, height: 32)
							.onAppear(perform: getAudioRouteImage)
							.onReceive(pub) { _ in
								self.getAudioRouteImage()
							}
						
					}
					.frame(width: 60, height: 60)
					.background(Color.gray500)
					.cornerRadius(40)
				}
				.frame(height: geo.size.height * 0.15)
				.padding(.horizontal, 20)
				.padding(.top, (orientation != .landscapeLeft && orientation != .landscapeRight) ? (geo.safeAreaInsets.bottom != 0 ? -15 : -30) : -10)
				
				if orientation != .landscapeLeft && orientation != .landscapeRight {
					HStack(spacing: 0) {
						VStack {
							Button {
							} label: {
								Image("phone-transfer")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Transfer")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
							} label: {
								Image("phone-plus")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("New call")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
							} label: {
								Image("phone-list")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Call list")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
							} label: {
								Image("dialer")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Dialer")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						
					}
					.frame(height: geo.size.height * 0.15)
					
					HStack(spacing: 0) {
						VStack {
							Button {
							} label: {
								Image("chat-teardrop-text")
									.renderingMode(.template)
									.resizable()
								//.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							//.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray600 : Color.gray500)
							.background(Color.gray600)
							.cornerRadius(40)
							//.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
							.disabled(true)
							
							Text("Messages")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
								callViewModel.togglePause()
							} label: {
								Image(callViewModel.isPaused ? "play" : "pause")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(telecomManager.isPausedByRemote ? Color.gray500 : .white)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(telecomManager.isPausedByRemote ? Color.gray600 : (callViewModel.isPaused ? Color.greenSuccess500 : Color.gray500))
							.cornerRadius(40)
							.disabled(telecomManager.isPausedByRemote)
							
							Text("Pause")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
								callViewModel.toggleRecording()
							} label: {
								Image("record-fill")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray600 : (callViewModel.isRecording ? Color.redDanger500 : Color.gray500))
							.cornerRadius(40)
							.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
							
							Text("Record")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						
						VStack {
							Button {
							} label: {
								Image("video-camera")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray500)
							.cornerRadius(40)
							
							Text("Disposition")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
						.hidden()
					}
					.frame(height: geo.size.height * 0.15)
				} else {
					HStack {
						VStack {
							Button {
							} label: {
								Image("phone-transfer")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Transfer")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
							} label: {
								Image("phone-plus")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("New call")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
							} label: {
								Image("phone-list")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Call list")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
							} label: {
								Image("dialer")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(Color.gray600)
							.cornerRadius(40)
							.disabled(true)
							
							Text("Dialer")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						
						
						VStack {
							Button {
							} label: {
								Image("chat-teardrop-text")
									.renderingMode(.template)
									.resizable()
								//.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
									.foregroundStyle(Color.gray500)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							//.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray600 : Color.gray500)
							.background(Color.gray600)
							.cornerRadius(40)
							//.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
							.disabled(true)
							
							Text("Messages")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
								callViewModel.togglePause()
							} label: {
								Image(callViewModel.isPaused ? "play" : "pause")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(telecomManager.isPausedByRemote ? Color.gray500 : .white)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background(telecomManager.isPausedByRemote ? Color.gray600 : (callViewModel.isPaused ? Color.greenSuccess500 : Color.gray500))
							.cornerRadius(40)
							.disabled(telecomManager.isPausedByRemote)
							
							Text("Pause")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
								callViewModel.toggleRecording()
							} label: {
								Image("record-fill")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
									.frame(width: 32, height: 32)
							}
							.frame(width: 60, height: 60)
							.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray600 : (callViewModel.isRecording ? Color.redDanger500 : Color.gray500))
							.cornerRadius(40)
							.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
							
							Text("Record")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
					}
					.frame(height: geo.size.height * 0.15)
					.padding(.horizontal, 20)
					.padding(.top, 30)
				}
				Spacer()
			}
			.background(Color.gray900)
			.frame(maxHeight: .infinity, alignment: .top)
		}
	}
	
	func getAudioRouteImage() {
		imageAudioRoute = AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue == "Speaker" }).isEmpty
		? (
			AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue.contains("Bluetooth") }).isEmpty
			? (
				callViewModel.isHeadPhoneAvailable()
				? "headset"
				: "speaker-slash"
			)
			: "bluetooth"
		)
		: "speaker-high"
	}
}

struct BottomSheetView<Content: View>: View {
	let content: Content
	
	@State var minHeight: CGFloat
	@State var maxHeight: CGFloat
	
	@State var currentHeight: CGFloat
	
	var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 0.0) {
				content
			}
			.onAppear {
				self.currentHeight = minHeight
			}
			.frame(
				width: geometry.size.width,
				height: maxHeight,
				alignment: .top
			)
			.clipShape(
				Path(
					UIBezierPath(
						roundedRect: CGRect(x: 0.0, y: 0.0, width: geometry.size.width, height: maxHeight),
						byRoundingCorners: [.topLeft, .topRight],
						cornerRadii: CGSize(width: 16.0, height: 16.0)
					)
					.cgPath
				)
			)
			.frame(
				height: geometry.size.height,
				alignment: .bottom
			)
			.highPriorityGesture(
				DragGesture()
					.onChanged { value in
						currentHeight -= value.translation.height
						currentHeight = min(max(currentHeight, minHeight), maxHeight)
					}
					.onEnded { _ in
						withAnimation {
							currentHeight = (currentHeight - minHeight <= maxHeight - currentHeight) ? minHeight : maxHeight
						}
					}
			)
			.offset(y: maxHeight - currentHeight)
		}
		.edgesIgnoringSafeArea(.bottom)
	}
}

#Preview {
	CallView(callViewModel: CallViewModel())
}
// swiftlint:enable type_body_length
// swiftlint:enable line_length
