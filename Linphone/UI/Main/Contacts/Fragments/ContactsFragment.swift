/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
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

import SwiftUI

struct ContactsFragment: View {
    
    @ObservedObject var magicSearch = MagicSearchSingleton.shared
    @ObservedObject var contactViewModel: ContactViewModel
    
    @State private var orientation = UIDevice.current.orientation
    
    @State var isFavoriteOpen: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            if !magicSearch.lastSearch.filter({ $0.friend?.starred == true }).isEmpty {
                HStack(alignment: .center) {
                    Text("Favourites")
                        .default_text_style_800(styleSize: 16)
                    
                    Spacer()
                    
                    Image(isFavoriteOpen ? "caret-up" : "caret-down")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.grayMain2c600)
                        .frame(width: 25, height: 25, alignment: .leading)
                }
                .padding(.top, 30)
                .padding(.horizontal, 16)
                .background(.white)
                .onTapGesture {
                    withAnimation {
                        isFavoriteOpen.toggle()
                    }
                }
                
                if isFavoriteOpen {
                    FavoriteContactsListFragment(contactViewModel: contactViewModel, favoriteContactsListViewModel: FavoriteContactsListViewModel())
                        .zIndex(-1)
                        .transition(.move(edge: .top))
                }
                
                HStack(alignment: .center) {
                    Text("All contacts")
                        .default_text_style_800(styleSize: 16)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
            }
            ContactsListFragment(contactViewModel: contactViewModel, contactsListViewModel: ContactsListViewModel())
        }
        .navigationBarHidden(true)
        .onRotate { newOrientation in
            orientation = newOrientation
        }
        
    }
}

#Preview {
    ContactsFragment(contactViewModel: ContactViewModel())
}
