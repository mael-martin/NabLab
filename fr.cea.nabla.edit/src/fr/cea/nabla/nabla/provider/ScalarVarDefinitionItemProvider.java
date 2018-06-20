/**
 * generated by Xtext 2.12.0
 */
package fr.cea.nabla.nabla.provider;


import fr.cea.nabla.nabla.NablaFactory;
import fr.cea.nabla.nabla.NablaPackage;
import fr.cea.nabla.nabla.ScalarVarDefinition;

import java.util.Collection;
import java.util.List;

import org.eclipse.emf.common.notify.AdapterFactory;
import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EStructuralFeature;

import org.eclipse.emf.edit.provider.ComposeableAdapterFactory;
import org.eclipse.emf.edit.provider.IItemPropertyDescriptor;
import org.eclipse.emf.edit.provider.ItemPropertyDescriptor;
import org.eclipse.emf.edit.provider.ViewerNotification;

/**
 * This is the item provider adapter for a {@link fr.cea.nabla.nabla.ScalarVarDefinition} object.
 * <!-- begin-user-doc -->
 * <!-- end-user-doc -->
 * @generated
 */
public class ScalarVarDefinitionItemProvider extends InstructionItemProvider {
	/**
	 * This constructs an instance from a factory and a notifier.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public ScalarVarDefinitionItemProvider(AdapterFactory adapterFactory) {
		super(adapterFactory);
	}

	/**
	 * This returns the property descriptors for the adapted class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public List<IItemPropertyDescriptor> getPropertyDescriptors(Object object) {
		if (itemPropertyDescriptors == null) {
			super.getPropertyDescriptors(object);

			addConstPropertyDescriptor(object);
			addTypePropertyDescriptor(object);
		}
		return itemPropertyDescriptors;
	}

	/**
	 * This adds a property descriptor for the Const feature.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected void addConstPropertyDescriptor(Object object) {
		itemPropertyDescriptors.add
			(createItemPropertyDescriptor
				(((ComposeableAdapterFactory)adapterFactory).getRootAdapterFactory(),
				 getResourceLocator(),
				 getString("_UI_ScalarVarDefinition_const_feature"),
				 getString("_UI_PropertyDescriptor_description", "_UI_ScalarVarDefinition_const_feature", "_UI_ScalarVarDefinition_type"),
				 NablaPackage.Literals.SCALAR_VAR_DEFINITION__CONST,
				 true,
				 false,
				 false,
				 ItemPropertyDescriptor.BOOLEAN_VALUE_IMAGE,
				 null,
				 null));
	}

	/**
	 * This adds a property descriptor for the Type feature.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected void addTypePropertyDescriptor(Object object) {
		itemPropertyDescriptors.add
			(createItemPropertyDescriptor
				(((ComposeableAdapterFactory)adapterFactory).getRootAdapterFactory(),
				 getResourceLocator(),
				 getString("_UI_ScalarVarDefinition_type_feature"),
				 getString("_UI_PropertyDescriptor_description", "_UI_ScalarVarDefinition_type_feature", "_UI_ScalarVarDefinition_type"),
				 NablaPackage.Literals.SCALAR_VAR_DEFINITION__TYPE,
				 true,
				 false,
				 false,
				 ItemPropertyDescriptor.GENERIC_VALUE_IMAGE,
				 null,
				 null));
	}

	/**
	 * This specifies how to implement {@link #getChildren} and is used to deduce an appropriate feature for an
	 * {@link org.eclipse.emf.edit.command.AddCommand}, {@link org.eclipse.emf.edit.command.RemoveCommand} or
	 * {@link org.eclipse.emf.edit.command.MoveCommand} in {@link #createCommand}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Collection<? extends EStructuralFeature> getChildrenFeatures(Object object) {
		if (childrenFeatures == null) {
			super.getChildrenFeatures(object);
			childrenFeatures.add(NablaPackage.Literals.SCALAR_VAR_DEFINITION__VARIABLE);
			childrenFeatures.add(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE);
		}
		return childrenFeatures;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EStructuralFeature getChildFeature(Object object, Object child) {
		// Check the type of the specified child object and return the proper feature to use for
		// adding (see {@link AddCommand}) it as a child.

		return super.getChildFeature(object, child);
	}

	/**
	 * This returns ScalarVarDefinition.gif.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object getImage(Object object) {
		return overlayImage(object, getResourceLocator().getImage("full/obj16/ScalarVarDefinition"));
	}

	/**
	 * This returns the label text for the adapted class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getText(Object object) {
		ScalarVarDefinition scalarVarDefinition = (ScalarVarDefinition)object;
		return getString("_UI_ScalarVarDefinition_type") + " " + scalarVarDefinition.isConst();
	}
	

	/**
	 * This handles model notifications by calling {@link #updateChildren} to update any cached
	 * children and by creating a viewer notification, which it passes to {@link #fireNotifyChanged}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void notifyChanged(Notification notification) {
		updateChildren(notification);

		switch (notification.getFeatureID(ScalarVarDefinition.class)) {
			case NablaPackage.SCALAR_VAR_DEFINITION__CONST:
			case NablaPackage.SCALAR_VAR_DEFINITION__TYPE:
				fireNotifyChanged(new ViewerNotification(notification, notification.getNotifier(), false, true));
				return;
			case NablaPackage.SCALAR_VAR_DEFINITION__VARIABLE:
			case NablaPackage.SCALAR_VAR_DEFINITION__DEFAULT_VALUE:
				fireNotifyChanged(new ViewerNotification(notification, notification.getNotifier(), true, false));
				return;
		}
		super.notifyChanged(notification);
	}

	/**
	 * This adds {@link org.eclipse.emf.edit.command.CommandParameter}s describing the children
	 * that can be created under this object.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected void collectNewChildDescriptors(Collection<Object> newChildDescriptors, Object object) {
		super.collectNewChildDescriptors(newChildDescriptors, object);

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__VARIABLE,
				 NablaFactory.eINSTANCE.createScalarVar()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createExpression()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createReal2Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createReal3Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createVarRef()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createOr()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createAnd()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createEquality()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createComparison()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createPlus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createMinus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createMulOrDiv()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createParenthesis()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createUnaryMinus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createNot()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createIntConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createRealConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createBoolConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createReal2x2Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createReal3x3Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createRealXCompactConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createMinConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createMaxConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createFunctionCall()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.SCALAR_VAR_DEFINITION__DEFAULT_VALUE,
				 NablaFactory.eINSTANCE.createReductionCall()));
	}

}
