/**
 * generated by Xtext 2.12.0
 */
package fr.cea.nabla.nabla.provider;


import fr.cea.nabla.nabla.If;
import fr.cea.nabla.nabla.NablaFactory;
import fr.cea.nabla.nabla.NablaPackage;

import java.util.Collection;
import java.util.List;

import org.eclipse.emf.common.notify.AdapterFactory;
import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EStructuralFeature;

import org.eclipse.emf.edit.provider.IItemPropertyDescriptor;
import org.eclipse.emf.edit.provider.ViewerNotification;

/**
 * This is the item provider adapter for a {@link fr.cea.nabla.nabla.If} object.
 * <!-- begin-user-doc -->
 * <!-- end-user-doc -->
 * @generated
 */
public class IfItemProvider extends InstructionItemProvider {
	/**
	 * This constructs an instance from a factory and a notifier.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public IfItemProvider(AdapterFactory adapterFactory) {
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

		}
		return itemPropertyDescriptors;
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
			childrenFeatures.add(NablaPackage.Literals.IF__CONDITION);
			childrenFeatures.add(NablaPackage.Literals.IF__THEN);
			childrenFeatures.add(NablaPackage.Literals.IF__ELSE);
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
	 * This returns If.gif.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object getImage(Object object) {
		return overlayImage(object, getResourceLocator().getImage("full/obj16/If"));
	}

	/**
	 * This returns the label text for the adapted class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getText(Object object) {
		return getString("_UI_If_type");
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

		switch (notification.getFeatureID(If.class)) {
			case NablaPackage.IF__CONDITION:
			case NablaPackage.IF__THEN:
			case NablaPackage.IF__ELSE:
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
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createExpression()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createReal2Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createReal3Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createVarRef()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createOr()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createAnd()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createEquality()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createComparison()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createPlus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createMinus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createMulOrDiv()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createParenthesis()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createUnaryMinus()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createNot()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createIntConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createRealConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createBoolConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createReal2x2Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createReal3x3Constant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createRealXCompactConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createMinConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createMaxConstant()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createFunctionCall()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__CONDITION,
				 NablaFactory.eINSTANCE.createReductionCall()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createInstruction()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createScalarVarDefinition()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createInstructionBlock()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createAffectation()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createLoop()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__THEN,
				 NablaFactory.eINSTANCE.createIf()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createInstruction()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createScalarVarDefinition()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createInstructionBlock()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createAffectation()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createLoop()));

		newChildDescriptors.add
			(createChildParameter
				(NablaPackage.Literals.IF__ELSE,
				 NablaFactory.eINSTANCE.createIf()));
	}

	/**
	 * This returns the label text for {@link org.eclipse.emf.edit.command.CreateChildCommand}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getCreateChildText(Object owner, Object feature, Object child, Collection<?> selection) {
		Object childFeature = feature;
		Object childObject = child;

		boolean qualify =
			childFeature == NablaPackage.Literals.IF__THEN ||
			childFeature == NablaPackage.Literals.IF__ELSE;

		if (qualify) {
			return getString
				("_UI_CreateChild_text2",
				 new Object[] { getTypeText(childObject), getFeatureText(childFeature), getTypeText(owner) });
		}
		return super.getCreateChildText(owner, feature, child, selection);
	}

}
