//
//  CreateRecipeView.swift
//  Cookity
//
//  Created by MihailsKuznecovs on 25/01/2021.
//  Copyright © 2021 Mihails Kuznecovs. All rights reserved.
//

import SwiftUI

struct CreateRecipeView: View {
    @State private var recipeName = ""
    @State private var ingridientName = ""
    @State private var ingridientAmount = ""
    @State private var ingridientMeasure = ""
    
    @State private var recipeStep = ""
    
    
    var body: some View {
        VStack {
            Spacer(minLength: 20)
            HStack(spacing: 30) {
                Button {
                    
                } label: {
                    Image(systemName: "multiply.circle")
                        .resizable()
                        .frame(width: 25, height: 25, alignment: .center)
                        .foregroundColor(Color(Colors.appColor!))
                }

                Spacer()
                Button {
                } label: {
                    Image(systemName: "trash")
                        .resizable()
                        .frame(width: 25, height: 25, alignment: .center)
                        .foregroundColor(Color(Colors.appColor!))
                }
            }
            TextField("Recipe name", text: $recipeName)
                .frame(width: 200, height: 50, alignment: .center)
                .border(Color.white)
            Form {
                Section(header: Text("Write ingridients for the recipe:")) {
                    HStack {
                        TextField("Ingridient", text: $ingridientName)
                        TextField("How much?", text: $ingridientAmount)
                        TextField("Pieces", text: $ingridientMeasure)
                        Button {
                            
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(Color(Colors.appColor!))
                        }

                    }
                    Text("HelloWorld")
                    Text("HelloWorld")
                    Text("HelloWorld")
                    Text("HelloWorld")
                }
                Section(header: Text("Describe cooking process:")) {
                    HStack {
                        if #available(iOS 14.0, *) {
                            TextEditor(text: $recipeStep)
                        } else {
                            TextField("Enter recipe step", text: $recipeStep)
                        }
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(Color(Colors.appColor!))
                        }
                    }
                    Text("RecipeSteps")
                }
                
                Section(header: Text("Recipe image")) {
                    Image(uiImage: UIImage(named: "emptyCart")!)
                    Button("Add image") { }
                }
                
                Section {
                    Button {
                        print("recipe Saved")
                    } label: {
                        Text("Save recipe")
                            .foregroundColor(Color.white)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, maxHeight: .infinity, alignment: .center)
                            .background(Color(Colors.appColor!))
                            .cornerRadius(10)
                    }
                }
                .listRowBackground(Color(UIColor.systemBackground))
            }
        }
        .gesture(
            TapGesture()
                .onEnded {
                    print("Tap gesture")
                }
        )
    }

}

struct CreateRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRecipeView()
    }
}
